--!nocheck
export type Identifiable = {
	_id: string;
	getId: () -> string;
}

export type flipDirection = "x" | "horizontal" | "y" | "vertical"

export type MatrixInstance<V = number> = Identifiable & {
	matrix: {V};
	rows: number;
	cols: number;
	entries: number;
	isHomogeneousMatrix: boolean;
	
	add: (b: Matrix<V>) -> Matrix<V>;
	subtract: (b: Matrix<V>) -> Matrix<V>;
	multiply: (b: Matrix<V> | number) -> Matrix<V>;
	divide: (b: Matrix<V> | number) -> Matrix<V>;
	determinant: () -> number;
	forwardSub: (b: Vec<V>) -> Vec<V>;
	backwardSub: (b: Vec<V>) -> Vec<V>;
	inverse: () -> Matrix<V>;
	rref: () -> Matrix<V>;
	getRank: () -> number;
	luDecompose: () -> Matrix<V>;
	transpose: () -> Matrix<V>;
	flip: (direction: flipDirection) -> Matrix<V>;
	rotate90: () -> Matrix<V>;
	toHomogeneous: () -> Matrix<V>;
	fromTransform: () -> Matrix<V>;
	transformVec: (vec: Vec<V>) -> Vec<V>;
	clone: () -> Matrix<V>;
	trace: () -> number;
	fill: (n: number) -> Matrix<V>;
	isZero: () -> boolean;
	forEach: (fn : (value: number, rows: number, cols: number) -> ()) -> nil;
	map: (fn: (value: number, rows: number, cols: number) -> ()) -> Matrix<V>;
	find: (target : number) -> {number};
	flatten: () -> {number};
	getDimension: () -> string;
	shape: () -> {number};
	isSquare: () -> boolean;
	unFlatten: (T: {number}, rows: number, cols: number) -> Matrix<V>;
}

export type MatrixConstructor<V = number> = {
	new: (Data: {number}, Name : string?) -> Matrix<V>;
	isEqual: (a: Matrix<V>, b: Matrix<V>) -> boolean;
	printm: (... Matrix<V>) -> string;
	getMatrixFromId: (id : string) -> Matrix<V>;
	identity: (n: number) -> Matrix<V>;
	zero: (n: number) -> Matrix<V>;
}

export type Matrix<V = number> = MatrixInstance<V> & MatrixConstructor<V>

export type VecInstance<V = number> = {
	vec: {V};
	dimension: number;
	_id: string;
	isHomogeneous: boolean;
	
	add: (b : Vec<V> | number) -> Vec<V>;
	subtract: (b : Vec<V> | number) -> Vec<V>;
	multiply: (b : Vec<V> | number) -> Vec<V>;
	divide: (b : Vec<V> | number) -> Vec<V>;
	cross: (b : Vec<V>) -> Vec<V>;
	rotate2D: (deg : number) -> Vec<V>;
	magnitude: () -> number;
	normalize: () -> Vec<V>;
	dot: (b : Vec<V>) -> number;
	distance: (b : Vec<V>) -> number;
	project: (b : Vec<V>) -> Vec<V>;
	value: () -> {number};
	reflect: (normal : Vec<V>) -> Vec<V>;
	clamp: (min : number, max : number) -> Vec<V>;
	toHomogeneous: () -> Vec<V>;
	fromHomogeneous: () -> Vec<V>;
	homogeneousEquals: (v2 : Vec<V>) -> boolean;
	inHomogeneous: () -> boolean;
	angleBetween: (b : Vec<V>) -> number;
	isParallel: (b : Vec<V>) -> boolean;
	isOrthogonal: (b : Vec<V>) -> boolean;
	equals: (b : Vec<V>, tolerance : number) -> boolean;
	lerp: (to : Vec<V>, t : number) -> Vec<V>;
	clone: () -> Vec<V>;
}

export type VecConstructor<V = number> = {
	new: (Data : {number}, Name : string?) -> Vec<V>;
	axis: (n : number, i : number) -> Vec<V>;
	unit: (n : number, i : number) -> Vec<V>;
	mask: (... number) -> Vec<V>;
	zero: (n : number) -> Vec<V>;
	printv: (... Vec<V>) -> string;
}

export type Vec<V = number> = VecInstance<V> & VecConstructor<V>

export type ErrorTypes = "Info" | "Warning" | "Error" | "Critical"

export type RuntimeError = {
	code: number;
	severity: ErrorTypes;
	message: string;
	trace: string?;
}

export type ErrorFn = {
	create: (severity : ErrorTypes, code : number, message : string, trace : string?) -> RuntimeError
}

export type Version = {
	major : number;
	minor : number;
	patch : number?;
	label : string?;
}

export type Mathsm = {
	Version: Version;
	
	Matrix : Matrix<number>;
	Vec: Vec<number>;
	
}

return nil
