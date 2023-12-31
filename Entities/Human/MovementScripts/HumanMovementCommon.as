// Runner Common

shared class HumanMoveVars
{
	//walking vars
	f32 walkSpeed = 0;
	f32 walkSpeedInAir;

	bool canJump;
	f32 jumpVel;
	int jumpState;

	f32 swimspeed;

	//extra force applied while... stopping
	f32 stoppingForce;
	f32 stoppingForceAir;
};