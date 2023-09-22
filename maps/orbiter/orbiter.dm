#if !defined(using_map_DATUM)
	#include "orbiter_areas.dm"
	#include "orbiter_shuttles.dm"
	#include "orbiter_radio.dm"
	#include "orbiter_unit_testing.dm"

	//[INF]	Customs-require
	#include "compile_required_snatch.dm"
	//[/INF]
	#include "orbiter_define.dm"

	#include "orbiter-1.dmm"

	#define using_map_DATUM /datum/map/orbiter

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Example

#endif
