#ifndef UNITY_MINI_VECTOR3_
#define UNITY_MINI_VECTOR3_

struct Vector3f {
	Vector3f(float x_ = 0.0f, float y_ = 0.0f, float z_ = 0.0f) : x(x_), y(y_), z(z_) {}
	float x, y, z;
};

#endif
