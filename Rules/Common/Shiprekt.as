#define SERVER_ONLY
#include "Booty.as"
#include "IslandsCommon.as";
#include "MakeBlock.as"
#include "BlockCommon.as"

const u16 STATION_BOOTY = 4;

void onInit(CRules@ this)
{
	this.set_bool( "whirlpool", true );
	setStartingBooty( this );
	server_resetTotalBooty( this ); 
}

void onTick(CRules@ this)
{
	u32 gameTime = getGameTime();
	//check for minimum resources on captains
	if ( gameTime % 150 == 0 && !this.get_bool( "whirlpool" ) )
	{
		u16 minBooty = this.get_u16( "bootyRefillLimit" );
		CBlob@[] cores;
		getBlobsByTag( "mothership", @cores );
		for ( u8 i = 0; i < cores.length; i++ )
		{
			Island@ isle = getIsland( cores[i].getShape().getVars().customData );
			if ( isle !is null && isle.owner != "" && isle.owner  != "*" )
			{
				u16 captainBooty = server_getPlayerBooty( isle.owner );
				if ( captainBooty < minBooty )
				{
					CPlayer@ player = getPlayerByUsername( isle.owner );
					if ( player is null )	continue;
					
					//consider blocks to propellers ratio
					int propellers = 1;
					int couplings = 0;
					for ( uint b_iter = 0; b_iter < isle.blocks.length; ++b_iter )
					{
						CBlob@ b = getBlobByNetworkID( isle.blocks[b_iter].blobID );
						if ( b !is null )
							if ( b.hasTag( "propeller" ) )
								propellers++;
							else if ( b.hasTag( "coupling" ) )
								couplings++;
					}

					if ( ( ( isle.blocks.length - propellers - couplings )/propellers > 3 ) || gameTime < this.get_u16( "warmup_time" ) )
					{
						CBlob@ pBlob = player.getBlob();
						CBlob@[]@ blocks;
						if ( pBlob !is null && pBlob.get( "blocks", @blocks ) && blocks.size() == 0 )
							server_setPlayerBooty( isle.owner, captainBooty + Maths::Min( 15, minBooty - captainBooty ));
					}
				}				
			}
		}
		
		for(int i = 0; i < getPlayersCount(); ++i)
		{
			CPlayer@ player = getPlayer(i);
			u8 pteam = player.getTeamNum();
			if ( player is null )	
				continue;
				
			u16 pBooty = server_getPlayerBooty( player.getUsername() );
			
			u16 pStationCount = 0;
			CBlob@[] stations;
			getBlobsByTag( "station", @stations );
			for ( u8 u = 0; u < stations.length; u++ )
			{
				CBlob@ station = stations[u];
				if ( station is null )
					continue;
			
				if ( stations[u].getTeamNum() == pteam )
					pStationCount++;
			}
			
			CBlob@ pBlob = player.getBlob();
			if ( pBlob !is null )
			{
				server_setPlayerBooty( player.getUsername(), pBooty + STATION_BOOTY*pStationCount);
				server_updateTotalBooty( pteam, STATION_BOOTY*pStationCount );
			}
		}
	}
	
	//after some secs, balance starting booty for teams with less players than the average
	if ( gameTime == 500 )
	{
		CBlob@[] cores;
		getBlobsByTag( "mothership", @cores );
		u8 teams = cores.length;
		u16 initBooty = Maths::Round( getRules().get_u16( "starting_booty" ) * 0.75f );
		u8 players = getPlayersCount();
		u8 median = Maths::Round( players/teams );
		//player per team
		u8[] teamPlayers;
		for ( u8 t = 0; t < 16; t++ )
			teamPlayers.push_back(0);
		
		for ( u8 p = 0; p < players; p++ )
		{
			u8 team = getPlayer(p).getTeamNum();
			if ( team < teamPlayers.length )
				teamPlayers[ team ]++;
		}
		
		print( "** Balancing booty: median = " + median + " for " + players + " players in " + teams + " teams" );
		//balance booty
		for ( u8 p = 0; p < players; p++ )
		{
			CPlayer@ player = getPlayer(p);
			u8 team = player.getTeamNum();
			if ( team >= teamPlayers.length )	continue;
				
			f32 compensate = median/teamPlayers[ team ];
			if ( compensate > 1 )
			{
				u16 balance = Maths::Round( initBooty * compensate/teamPlayers[ team ] - initBooty );
				string name = player.getUsername();
				u16 pBooty = server_getPlayerBooty( name );
				server_setPlayerBooty( name, pBooty + balance );
			}
		}
	}
}

void onRestart( CRules@ this )
{
	setStartingBooty( this );
	server_resetTotalBooty( this );
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	string pName = player.getUsername();
	u16 pBooty = server_getPlayerBooty( pName );
	u16 minBooty = Maths::Round( this.get_u16( "bootyRefillLimit" ) / 2 );
	if ( sv_test )
		server_setPlayerBooty( pName, 9999 );
	else if ( pBooty > minBooty )
	{
		this.set_u16( "booty" + pName, pBooty );
		this.Sync( "booty" + pName, true );
	}
	else
		server_setPlayerBooty( pName, getGameTime() > this.get_u16( "warmup_time" ) ? minBooty : this.get_u16( "starting_booty" ) );
		
	print("New player joined. New count : " + getPlayersCount());
	if (getPlayersCount() <= 1)
	{
		//print("*** Restarting the map to be fair to the new player ***");
		getNet().server_SendMsg( "*** " + getPlayerCount() + " player(s) in map. Setting freebuild mode until more players join. ***" );
		this.set_bool( "freebuild", true );
	}

	player.server_setTeamNum(0);
}

bool onServerProcessChat( CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player )
{
	if (player is null )
		return true;

	CBlob@ b = player.getBlob(); 
	if (b !is null)
	{
		//Blob3D@ blob; if (!b.get("blob",@blob)) return true;

		int team = b.getTeamNum();
		Vec2f pos = b.getPosition();
		{
			if (text_in == "!bot")
			{
				AddBot("Henry");
				return true;
			}
			else if (text_in.substr(0, 1) == "!")
			{
				// otherwise, try to spawn an actor with this name !actor
				string name = text_in.substr(1, text_in.size());
				if (server_CreateBlob(name, team, pos) is null)
				{
					client_AddToChat("blob " + text_in + " not found", SColor(255, 255, 0, 0));
				}
			}
		}
	}	


	if ( player.isMod() )
	{
		if (text_in.substr(0,1) == "!" )
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if (tokens[0] == "!team")
				{
					int team = parseInt(tokens[1]);
					player.getBlob().server_setTeamNum(team);
					//player.server_setTeamNum( parseInt( tokens[1] ));
					//if ( player.getBlob() !is null )
					//	player.getBlob().server_Die();
					
					return false;
				}
			}
		}
	}

	//for testing
	if ( sv_test || player.isMod() )
	{
		if (text_in.substr(0,1) == "!" )
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if ( tokens[0] == "!saveship" )
				{
					ConfigFile cfg;
					
					CBlob@ pBlob = player.getBlob();
					if ( pBlob is null )
						return false;
					
					Vec2f playerPos = pBlob.getPosition();
					Island@ isle = getIsland( player.getBlob() );
					int numBlocks = isle.blocks.length;
					cfg.add_u16("total blocks", numBlocks);
					for (uint b_iter = 0; b_iter < numBlocks; ++b_iter)
					{
						IslandBlock@ isle_block = isle.blocks[b_iter];
						if(isle_block is null) continue;

						CBlob@ block = getBlobByNetworkID( isle_block.blobID );
						if(block is null) continue;
						
						cfg.add_u16("block" + b_iter + "type", block.getSprite().getFrame());
						cfg.add_f32("block" + b_iter + "positionX", (block.getPosition().x - playerPos.x));
						cfg.add_f32("block" + b_iter + "positionY", (block.getPosition().y - playerPos.y));
						cfg.add_f32("block" + b_iter + "angle", block.getAngleDegrees());
					}
					
					cfg.saveFile( "SHIP_" + tokens[1] + ".cfg" );
				}
				if ( tokens[0] == "!loadship" )
				{
					ConfigFile cfg;
					
					if ( !cfg.loadFile( "../Cache/SHIP_" + tokens[1] + ".cfg" ) )
						return false;
						
					CBlob@ pBlob = player.getBlob();
					if ( pBlob is null )
						return false;
						
					Vec2f playerPos = pBlob.getPosition();
				
					int numBlocks = cfg.read_u16("total blocks");
					for (uint b_iter = 0; b_iter < numBlocks; ++b_iter)
					{	
						u16 blockType = cfg.read_u16("block" + b_iter + "type");
						f32 blockPosX = cfg.read_f32("block" + b_iter + "positionX");
						f32 blockPosY = cfg.read_f32("block" + b_iter + "positionY");
						f32 blockAngle = cfg.read_f32("block" + b_iter + "angle");
						
						CBlob@ b = makeBlock( playerPos + Vec2f(blockPosX, blockPosY), blockAngle, blockType, pBlob.getTeamNum() );
					}
				}
			}
			else
			{
				if ( tokens[0] == "!deleteship" )
				{
					CBlob@ pBlob = player.getBlob();
					if ( pBlob is null )
						return false;
					
					Vec2f playerPos = pBlob.getPosition();
					Island@ isle = getIsland( player.getBlob() );
					int numBlocks = isle.blocks.length;
					if( getNet().isServer() ) 
					{
						for (uint b_iter = 0; b_iter < numBlocks; ++b_iter)
						{
							IslandBlock@ isle_block = isle.blocks[b_iter];
							if(isle_block is null) continue;

							CBlob@ block = getBlobByNetworkID( isle_block.blobID );
							if(block is null) continue;
							
							const int blockType = block.getSprite().getFrame();
							
							if ( !block.hasTag("mothership") )
							{
								block.Tag( "noCollide" );
								block.server_Die();
							}
						}
					}
				}
				if ( tokens[0] == "!clearmap" )
				{
					CBlob@[] blocks;
					if (getBlobsByName( "block", @blocks ))
					{							
						int numBlocks = blocks.length;
						if( getNet().isServer() ) 
						{
							for (uint b_iter = 0; b_iter < numBlocks; ++b_iter)
							{
								CBlob@ block = blocks[b_iter];
								if(block is null) continue;
								
								if ( !block.hasTag("mothership") )
								{
									block.Tag( "noCollide" );
									block.server_Die();
								}
							}
						}
					}
				}				
				if ( tokens[0] == "!booty" )
				{
					server_setPlayerBooty( player.getUsername(), 5000 );
					return false;
				}
					
				if ( tokens[0] == "!sd"  )
				{
					CMap@ map = getMap();
					Vec2f mapCenter = Vec2f( map.tilemapwidth * map.tilesize/2, map.tilemapheight * map.tilesize/2 );
					server_CreateBlob( "whirlpool", 0, mapCenter );
				}

				if ( tokens[0] == "!crit" )
				{
					CBlob@ mothershipBlue = getMothership(0);
					mothershipBlue.server_Hit( mothershipBlue, mothershipBlue.getPosition(), Vec2f_zero, 50.0f, 0, true );
				}
			}
		}
	}
	return true;
}