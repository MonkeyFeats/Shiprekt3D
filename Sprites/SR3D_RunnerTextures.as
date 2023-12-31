///////////////////////////////////////////////////////////////////////////////
// gender texture and head offset handling stuff
//
//		used for the default 2-gender runner classes in conjunction with
//		runnerhead.as - has functionality for storing it inside rules
//		for simplicity
//

#include "SR3D_PaletteSwap.as"
#include "PixelOffsets.as"

shared class SR3D_RunnerTextures
{
	string shortname;
	string filename;

	bool loaded;

	SR3D_RunnerTextures(string _shortname, string texture_prefix)
	{
		loaded = false;

		shortname = _shortname;
		filename = texture_prefix+".png";
	}

	void Load(Vec2f framesize)
	{
		if (loaded) return;
		loaded = true;
	}

	void Load(CSprite@ sprite)
	{
		if (loaded) return;
		Load(_sprite_to_framesize(sprite));
	}

	//get the texture name
	string texname()
	{
		return shortname;
	}
};

string getRunnerTeamTexture(SR3D_RunnerTextures@ textures, int gender, int team_num, int skin_num)
{
	if (textures is null) return "";
	return ApplyTeamTexture(textures.texname(), team_num, skin_num);
}

string getRunnerTextureName(CSprite@ sprite)
{
	CBlob@ b = sprite.getBlob();
	return getRunnerTeamTexture(getSR3D_RunnerTextures(sprite), b.getSexNum(), b.getTeamNum(), 0);
}

void setRunnerTexture(CSprite@ sprite)
{
	string t = getRunnerTextureName(sprite);

	//only change if we need it and if it exists
	if (sprite.getTextureName() != t && t != "")
	{
		sprite.SetTexture(t);
	}
}

//call this in oninit from the script housing the object
//it'll change the texture of the sprite to the one for the right gender as well

SR3D_RunnerTextures@ fetchRunnerTexture(string shortname, string texture_prefix)
{
	SR3D_RunnerTextures@ tex = null;
	string rules_key = "runner_tex_"+shortname+"_"+texture_prefix;
	if (!getRules().get(rules_key, @tex) || tex is null)
	{
		getRules().set(rules_key, SR3D_RunnerTextures(shortname, texture_prefix));
		//re-fetch
		return fetchRunnerTexture(shortname, texture_prefix);
	}
	return tex;
}

SR3D_RunnerTextures@ addSR3D_RunnerTextures(CSprite@ sprite, string shortname, string texture_prefix)
{
	//fetch it or set it up
	SR3D_RunnerTextures@ tex = fetchRunnerTexture(shortname, texture_prefix);
	//load it out
	tex.Load(sprite);
	//store needed stuff in blob
	CBlob@ b = sprite.getBlob();
	b.set("runner_textures", @tex);
	//set the correct texture
	setRunnerTexture(sprite);
	//done
	return tex;
}

//get the textures object directly

SR3D_RunnerTextures@ getSR3D_RunnerTextures(CBlob@ blob)
{
	SR3D_RunnerTextures@ tex = null;
	blob.get("runner_textures", @tex);
	return tex;
}

SR3D_RunnerTextures@ getSR3D_RunnerTextures(CSprite@ sprite)
{
	return getSR3D_RunnerTextures(sprite.getBlob());
}

//ensure the right texture is used
void ensureCorrectRunnerTexture(CSprite@ sprite, string shortname, string texture_prefix)
{
	SR3D_RunnerTextures@ tex = getSR3D_RunnerTextures(sprite);
	if (tex is null || tex.shortname != shortname)
	{
		//first time set up
		addSR3D_RunnerTextures(sprite, shortname, texture_prefix);
		ensureCorrectRunnerTexture(sprite, shortname, texture_prefix);
		return;
	}
	//just set the texture
	setRunnerTexture(sprite);
}
