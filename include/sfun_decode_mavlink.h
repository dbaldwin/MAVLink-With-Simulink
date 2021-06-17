/*
DO NOT EDIT.
This file was automatically created by the Matlab function 'create_sfun_decode' on 07-Aug-2020 10:58:54
as part of Simulink MAVLink library.
*/

#include "E:\rally\simulink_mavlink-master\include\sfun_mavlink_msg_attitude.h"
#include "E:\rally\simulink_mavlink-master\include\sfun_mavlink_msg_altitude.h"
#include "E:\rally\simulink_mavlink-master\include\sfun_mavlink_msg_vfr_hud.h"

#define NFIELDS_OUTPUT_BUS (NFIELDS_BUS_ATTITUDE + NFIELDS_BUS_ALTITUDE + NFIELDS_BUS_VFR_HUD)

#define OFFSET_ATTITUDE 0
#define OFFSET_ALTITUDE 2*(NFIELDS_BUS_ATTITUDE)
#define OFFSET_VFR_HUD 2*(NFIELDS_BUS_ALTITUDE+NFIELDS_BUS_ATTITUDE)

/*
Decode the incoming MAVLink message
*/
static inline void decode_mavlink_msg (SimStruct *S, const mavlink_message_t *msg)
{
	int_T *busInfo = (int_T *) ssGetUserData(S);

	char* yvec0 = (char *) ssGetOutputPortRealSignal(S, 0);
	char* yvec1 = (char *) ssGetOutputPortRealSignal(S, 1);
	char* yvec2 = (char *) ssGetOutputPortRealSignal(S, 2);
	switch (msg->msgid) {

		case MAVLINK_MSG_ID_ATTITUDE:
			decode_msg_attitude(msg, busInfo, yvec0, OFFSET_ATTITUDE);
			break;

		case MAVLINK_MSG_ID_ALTITUDE:
			decode_msg_altitude(msg, busInfo, yvec1, OFFSET_ALTITUDE);
			break;

		case MAVLINK_MSG_ID_VFR_HUD:
			decode_msg_vfr_hud(msg, busInfo, yvec2, OFFSET_VFR_HUD);
			break;
	}
}
