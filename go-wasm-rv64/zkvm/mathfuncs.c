#include "custom_shims.h"

double copysign(double a, double b) {
  if ((a < 0 && b > 0) || (a > 0 && b < 0)) return -a;
  return a;
}

double ceil(double x) {
	return (double) (int) x+1;
}

double floor(double x) {
	return (double) (int) x;
}

double trunc(double x) {
	return floor(x);
}

// fast-integer sqrt
double sqrt(double x) {
	unsigned int a, b;
	unsigned int val = (int)x;

	if (val < 2) return x;

	a = 1255;

	b = val / a; a = (a+b)/2;
	b = val / a; a = (a+b)/2;
	b = val / a; a = (a+b)/2;
	b = val / a; a = (a+b)/2;

	return (double) a;
}
