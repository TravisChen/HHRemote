#ifndef UNITY_MINI_VECTOR2_
#define UNITY_MINI_VECTOR2_

struct Vector2f {
	Vector2f(float x_ = 0.0f, float y_ = 0.0f) : x(x_), y(y_) {}
	float x, y;
	
	Vector2f& operator += (Vector2f const& rhs) { x += rhs.x; y += rhs.y; return *this; }
	Vector2f& operator -= (Vector2f const& rhs) { x -= rhs.x; y -= rhs.y; return *this; }
};
inline Vector2f operator + (const Vector2f& lhs, const Vector2f& rhs)	{ return Vector2f (lhs.x + rhs.x, lhs.y + rhs.y); }
inline Vector2f operator - (const Vector2f& lhs, const Vector2f& rhs)	{ return Vector2f (lhs.x - rhs.x, lhs.y - rhs.y); }

#endif
