#define CLIENT_ONLY

#include "IslandsCommon.as";
#include "TeamColour.as";

class CompassVars 
{
    SColor[] core_teams_cols;
    f32[] core_angles;
    f32[] core_distances;
	
    SColor[] station_teams_cols;
    f32[] station_angles;
    f32[] station_distances;
	
	f32 booty_angle;
	f32 booty_distance;

    CompassVars() {
        Reset();
    }

    void Reset() {
        core_angles.clear();
        core_teams_cols.clear();
        core_distances.clear();
        station_angles.clear();
        station_teams_cols.clear();
        station_distances.clear();
		booty_angle = 0.0f;
		booty_distance = -1.0f;
    }
};

CompassVars _vars;

void onTick( CRules@ this )
{
    _vars.Reset();

    CPlayer@ p = getLocalPlayer();
    if (p is null || !p.isMyPlayer()) {return; }

    CBlob@ b = p.getBlob();
	CCamera@ camera = getCamera();
    if(b is null && camera is null) return;    

    f32 camangle = camera.getRotation();
    Vec2f pos = b !is null ? b.getPosition() : camera.getPosition();
	u8 localTeamNum = p.getTeamNum();
	u8 specTeamNum = this.getSpectatorTeamNum();
	
	//cores
    CBlob@[] cores;
    getBlobsByTag( "mothership", @cores );
    for (uint i = 0; i < cores.length; i++)
    {
        CBlob@ core = cores[i];			

        Vec2f offset = ((core.getPosition()+Vec2f(8,8)) - pos);

		f32 distance = offset.Length();
		if (distance > 1000 || distance < 40)
		continue;

		f32 core_angle = -offset.Angle()+90; 
		if (core_angle < -180) core_angle+=360;
		if (core_angle > 180) core_angle-=360;
		f32 xang = ((core_angle-(camangle)));
		if (xang < -180) xang+=360;
		if (xang > 180) xang-=360;

		if (xang < -90 || xang > 90)
		continue;

		f32 angle=xang*1.8;

		float opacity = 255-Maths::Min(255,Maths::Abs(-0.9+Maths::Sin(distance/250))*255);
		SColor teamcolour = getTeamColor(core.getTeamNum());
		teamcolour.setAlpha(opacity);

        _vars.core_teams_cols.push_back(teamcolour);
        _vars.core_angles.push_back(angle); 
        _vars.core_distances.push_back(distance);
    }
	
	//station
    CBlob@[] stations;
    getBlobsByTag( "station", @stations );
    for (uint i = 0; i < stations.length; i++)
    {
        CBlob@ station = stations[i];			

        Vec2f offset = (station.getPosition() - pos);
		f32 station_angle = -offset.Angle()+90; 
		if (station_angle < -180) station_angle+=360;
		if (station_angle > 180) station_angle-=360;
		f32 xang = ((station_angle-(camangle+90)));
		if (xang < -180) xang+=360;
		if (xang > 180) xang-=360;

		if (xang < -90 || xang > 90)
		continue;

		f32 angle=xang*1.8;
		f32 distance = offset.Length();

		SColor tc = getTeamColor(station.getTeamNum());
		SColor col(255-Maths::Min(255,distance/10), tc.getRed(),tc.getGreen(),tc.getBlue());

        _vars.station_teams_cols.push_back(col);
        _vars.station_angles.push_back(angle); 
        _vars.station_distances.push_back(distance);
    }
	
	//booty
	CBlob@[] booty;
    getBlobsByTag( "booty", @booty );	
	f32 closestBootyDist = 999999.9f;
	s16 closestBootyIndex = -1;
    for (uint i = 0; i < booty.length; i++)
    {
        CBlob@ currBooty = booty[i];
		Vec2f bootyPos = currBooty.getPosition();
		f32 distToPlayer = (bootyPos - pos).getLength();
		f32 dist = distToPlayer;	
		if (currBooty.get_u16( "ammount" ) > 0 && dist < closestBootyDist)
		{
			closestBootyDist = dist;
			closestBootyIndex = i;
		}
		if (closestBootyIndex >= 999) 
		{
			break;
		}
    }
	
	if ( closestBootyIndex > -1 )
	{
		Vec2f bootyOffset = (booty[closestBootyIndex].getPosition() - pos);

		_vars.booty_angle = bootyOffset.Angle() * -1.0f; 
		_vars.booty_distance = bootyOffset.Length();
	}	
	
}

void onInit( CRules@ this )
{
    onRestart(this);
}

void onRestart( CRules@ this )
{
    _vars.Reset();
}

void onRender( CRules@ this )
{
    const string gui_image_fname = "GUI/compass.png";

	CControls@ controls = getControls();
	
	CPlayer@ p = getLocalPlayer();
	u8 localTeamNum = p !is null ? p.getTeamNum() : -1;

    float hSw = getDriver().getScreenWidth()/2;	
    Vec2f framesize = Vec2f(8,8);
    Vec2f center = Vec2f(hSw,50);		
	f32 scale = 1.0f;
	
    GUI::DrawIcon(gui_image_fname, 4, framesize, (center+Vec2f(0,16)), scale);

	////closest booty
	//if ( _vars.booty_distance > 0.0f && _vars.booty_distance < _vars.isle_distance )
	//{
    //    Vec2f pos(Maths::Min(18.0f, _vars.booty_distance / 48.0f), 0.0f);
    //    Vec2f framesize = Vec2f(16,16);
    //    pos.RotateBy(_vars.booty_angle - camangle);
    //    GUI::DrawIcon(gui_image_fname, 14, framesize, ( topLeft + (center + pos)*2.0f - framesize ) * scale, scale, 0);
    //}
	
	//station icons
    for (uint i = 0; i < _vars.station_teams_cols.length; i++)
    {
        Vec2f pos(_vars.station_angles[i]-framesize.x/2, 8.0f);
        GUI::DrawIcon(gui_image_fname, 1, framesize, center+pos,  1.6-Maths::Min(1.6f,_vars.station_distances[i]*0.0011), _vars.station_teams_cols[i]);
    }
//	
//	//human icons
//    for (uint i = 0; i < _vars.human_teams.length; i++)
//    {
//        Vec2f pos(Maths::Min(18.0f, _vars.human_distances[i] / 48.0f), 0.0f);
//        Vec2f framesize = Vec2f(8,8);
//		  bool borderZoom = localTeamNum != _vars.human_teams[i] && pos.x > 16.5f;
//		  pos.RotateBy(_vars.human_angles[i] - camangle);
//		  GUI::DrawIcon(gui_image_fname, 23, framesize, ( topLeft + (center + pos)*2.0f - framesize ) * scale, scale * ( borderZoom ? 1.25f : 1.0f ), _vars.human_teams[i]);
//    }
	
	
	//core icons
    for (uint i = 0; i < _vars.core_teams_cols.length; i++)
    {
        Vec2f pos(_vars.core_angles[i]-framesize.x/2, 8.0f);
        GUI::DrawIcon(gui_image_fname, 2, framesize, center+pos, 1.6-Maths::Min(1.6f,_vars.core_distances[i]*0.0011), _vars.core_teams_cols[i]);
    }
}
