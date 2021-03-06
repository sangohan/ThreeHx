package com.gamestudiohx.three.math;
import com.gamestudiohx.three.core.Object3D;

/**
 * @author bhouston / http://exocortex.com
 * @author WestLangley / http://github.com/WestLangley
 */

/**
 * 
 * @haxeport Krtolica Vujadin - GameStudioHx.com
 */
 
class Box3 {
	
	public var min:Vector3;
	public var max:Vector3;	

	public function new(min:Vector3 = null, max:Vector3 = null) {
		this.min = min != null ? min : new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		this.max = max != null ? max : new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
	}
	
	public function set(min:Vector3, max:Vector3):Box3 {
		this.min.copy(min);
		this.max.copy(max);
		return this;
	}
	
	public function addPoint(point:Vector3) {
		if (point.x < this.min.x) {
			this.min.x = point.x;
		} else if (point.x > this.max.x) {
			this.max.x = point.x;
		}

		if (point.y < this.min.y) {
			this.min.y = point.y;
		} else if (point.y > this.max.y) {
			this.max.y = point.y;
		}

		if (point.z < this.min.z) {
			this.min.z = point.z;
		} else if (point.z > this.max.z) {
			this.max.z = point.z;
		}
	}
	
	public function setFromPoints(points:Array<Dynamic>):Box3 {
		if (points.length > 0) {
			var point = points[0];

			this.min.copy(point);
			this.max.copy(point);

			for (i in 1...points.length) {
				this.addPoint(points[i]);
			}
		} else {
			this.makeEmpty();
		}

		return this;
	}	
	
	public function setFromCenterAndSize(center:Vector3, size:Vector3):Box3 {
		var v1 = new Vector3();
		var halfSize = v1.copy(size).multiplyScalar(0.5);
		this.min.copy(center).sub(halfSize);
		this.max.copy(center).add(halfSize);
		return this;
	}	
	
	public function setFromObject(object:Object3D):Box3 {
		// Computes the world-axis-aligned bounding box of an object (including its children),
		// accounting for both the object's, and childrens', world transforms
		var v1 = new Vector3();

		var scope = this;
		object.updateMatrixWorld(true);
		this.makeEmpty();

		object.traverse(function(node) {
			if (node.geometry != null && node.geometry.vertices != null) {
				var vertices:Array<Vector3> = node.geometry.vertices;
				for (i in 0...vertices.length) {
					v1.copy(vertices[i]);
					v1.applyMatrix4(node.matrixWorld);
					scope.expandByPoint(v1);
				}
			}
		});

		return this;
	}
	
	public function copy(box:Box3):Box3 {
		min.copy(box.min);
		max.copy(box.max);
		return this;
	}
	
	public function makeEmpty():Box3 {
		this.min.x = this.min.y = this.min.z = Math.POSITIVE_INFINITY;
		this.max.x = this.max.y = this.max.z = Math.NEGATIVE_INFINITY;
		return this;
	}	
	
	public function empty():Bool {
		// this is a more robust check for empty than ( volume <= 0 ) because volume can get positive with two negative axes
		return (this.max.x < this.min.x) || (this.max.y < this.min.y) || (this.max.z < this.min.z);
	}	
	
	public function center(optionalTarget:Vector3 = null):Vector3 {
		var result = optionalTarget != null ? optionalTarget : new Vector3();
		return result.addVectors(this.min, this.max).multiplyScalar(0.5);
	}	
	
	public function size(optionalTarget:Vector3 = null):Vector3 {
		var result = optionalTarget != null ? optionalTarget : new Vector3();
		return result.subVectors(max, min);
	}	
	
	public function expandByPoint(point:Vector3):Box3 {
		this.min.min(point);
		this.max.max(point);
		return this;
	}	
	
	public function expandByVector(vector:Vector3):Box3 {
		this.min.sub(vector);
		this.max.add(vector);
		return this;
	}	
	
	public function expandByScalar(scalar:Float):Box3 {
		this.min.addScalar(-scalar);
		this.max.addScalar(scalar);
		return this;
	}	
	
	public function containsPoint(point:Vector3):Bool {
		if (point.x < this.min.x || point.x > this.max.x ||
		     point.y < this.min.y || point.y > this.max.y ||
		     point.z < this.min.z || point.z > this.max.z) {
			return false;
		}

		return true;
	}	
	
	public function containsBox(box:Box3):Bool {
		if ((this.min.x <= box.min.x) && (box.max.x <= this.max.x) &&
			 (this.min.y <= box.min.y) && (box.max.y <= this.max.y) &&
			 (this.min.z <= box.min.z) && (box.max.z <= this.max.z)) {
			return true;
		}

		return false;
	}	
	
	public function getParameter(point:Vector3, optionalTarget:Vector3 = null):Vector3 {
		// This can potentially have a divide by zero if the box
		// has a size dimension of 0.
		var result = optionalTarget != null ? optionalTarget : new Vector3();
		return result.set(
			(point.x - min.x) / (max.x - min.x),
			(point.y - min.y) / (max.y - min.y),
			(point.z - min.z) / (max.z - min.z)
		);
	}	
	
	public function isIntersectionBox(box:Box3):Bool {
		// using 6 splitting planes to rule out intersections.
		if (box.max.x < this.min.x || box.min.x > this.max.x ||
		     box.max.y < this.min.y || box.min.y > this.max.y ||
		     box.max.z < this.min.z || box.min.z > this.max.z) {
			return false;
		}

		return true;
	}	
	
	public function clampPoint(point:Vector3, optionalTarget:Vector3 = null):Vector3 {
		var result = optionalTarget != null ? optionalTarget : new Vector3();
		return result.copy(point).clamp(this.min, this.max);
	}	
	
	public function distanceToPoint(point:Vector3):Float {
		var v1 = point.clone();
		var clampedPoint = v1.copy(point).clamp(this.min, this.max);
		return clampedPoint.sub(point).length();
	}	
	
	public function getBoundingSphere(optionalTarget:Sphere = null):Sphere {
		var v1 = new Vector3();
		var result = optionalTarget != null ? optionalTarget : new Sphere();

		result.center = this.center();
		result.radius = this.size(v1).length() * 0.5;

		return result;
	}	
	
	public function intersect(box:Box3):Box3 {
		this.min.max(box.min);
		this.max.min(box.max);

		return this;
	}	
	
	public function union(box:Box3):Box3 {
		this.min.min(box.min);
		this.max.max(box.max);

		return this;
	}	
	
	public function applyMatrix4(matrix:Matrix4):Box3 {
		var points:Array<Vector3> = [
			new Vector3(),
			new Vector3(),
			new Vector3(),
			new Vector3(),
			new Vector3(),
			new Vector3(),
			new Vector3(),
			new Vector3()
		];
		
		// NOTE: I am using a binary pattern to specify all 2^3 combinations below
		points[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(matrix); // 000
		points[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(matrix); // 001
		points[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(matrix); // 010
		points[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(matrix); // 011
		points[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(matrix); // 100
		points[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(matrix); // 101
		points[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(matrix); // 110
		points[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(matrix);  // 111

		this.makeEmpty();
		this.setFromPoints( points );

		return this;
	}	
	
	public function translate(offset:Vector3):Box3 {
		this.min.add(offset);
		this.max.add(offset);
		return this;
	}	
	
	public function equals(box:Box3):Bool {
		return box.min.equals(this.min) && box.max.equals(this.max);
	}	
	
	public function clone():Box3 {
		return new Box3().copy(this);
	}	
	
}

