package main

import (
	_ "embed"
	"fmt"
	"math/big"

	"example/serialization"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core"
	"github.com/ethereum/go-ethereum/core/stateless"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/core/vm"
	"github.com/ethereum/go-ethereum/params"
	"github.com/ethereum/go-ethereum/rlp"
)

//go:embed witness.bin
var witnessBytes []byte

var witnessOffset int = 0

func UnsafeReadFromEmbedded(n int) []byte {
	if witnessOffset+n > len(witnessBytes) {
		panic(fmt.Sprintf("failed to read %d bytes from embedded file: only %d bytes remaining", n, len(witnessBytes)-witnessOffset))
	}
	buf := make([]byte, n)
	copy(buf, witnessBytes[witnessOffset:witnessOffset+n])
	witnessOffset += n
	return buf
}

func Read[T any]() T {
	// Read the length first (8 bytes)
	// TODO: Note that this wastes bytes if we are serializing small structures like u8
	// TODO: since that will take up 72 bits. We can optimize this later.
	lengthBytes := UnsafeReadFromEmbedded(8)
	length := uint64(0)
	for i := 0; i < 8; i++ {
		length |= uint64(lengthBytes[i]) << (i * 8)
	}

	// Read the serialized data of the specified length
	data := UnsafeReadFromEmbedded(int(length))

	// Deserialize it into the result
	var result T
	serialization.DeserializeData(data, &result)

	return result
}

func main() {
	witnessBytes := Read[[]byte]()
	fmt.Printf("Read witness (%d bytes)\n", len(witnessBytes))

	// Deserialize the witness using RLP
	witness := new(stateless.Witness)
	if err := rlp.DecodeBytes(witnessBytes, witness); err != nil {
		panic(fmt.Sprintf("Failed to decode witness: %v", err))
	}
	fmt.Printf("Witness decoded - contains %d headers, %d state nodes, %d code entries\n",
		len(witness.Headers), len(witness.State), len(witness.Codes))

	// Read block bytes from zkVM input buffer
	blockBytes := Read[[]byte]()
	fmt.Printf("Read block (%d bytes)\n", len(blockBytes))

	// Deserialize the block using RLP
	block := new(types.Block)
	if err := rlp.DecodeBytes(blockBytes, block); err != nil {
		panic(fmt.Sprintf("Failed to decode block: %v", err))
	}
	fmt.Printf("Block decoded - #%d with %d transactions\n",
		block.Number().Uint64(), len(block.Transactions()))

	// Use the appropriate chain config
	config := *params.AllEthashProtocolChanges
	config.TerminalTotalDifficulty = common.Big0
	config.MergeNetsplitBlock = big.NewInt(11)

	// Set times for Shanghai and Cancun based on block timestamp
	timestamp := block.Time()
	shanghaiTime := timestamp - 10
	cancunTime := timestamp - 5
	config.ShanghaiTime = &shanghaiTime
	config.CancunTime = &cancunTime
	config.BlobScheduleConfig = params.DefaultBlobSchedule

	// Create VM config
	vmConfig := vm.Config{}

	// Execute stateless with the witness and block
	stateRoot, receiptRoot, err := core.ExecuteStateless(&config, vmConfig, block, witness)
	if err != nil {
		panic(fmt.Sprintf("ExecuteStateless failed: %v", err))
	}

	// Log the results
	fmt.Printf("ExecuteStateless succeeded!\n")
	fmt.Printf("State root: %x\n", stateRoot)
	fmt.Printf("Receipt root: %x\n", receiptRoot)
	fmt.Printf("Gas used: %d\n", block.GasUsed())

	// Verify non-empty roots
	if stateRoot == (common.Hash{}) {
		panic("State root is empty")
	}
	if receiptRoot == (common.Hash{}) {
		panic("Receipt root is empty")
	}
}
