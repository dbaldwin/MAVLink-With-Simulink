/*
DO NOT EDIT.
This file was automatically created by the Matlab function 'create_sfun_decode' on 07-Aug-2020 10:58:54
as part of Simulink MAVLink library.
*/

#define S_FUNCTION_NAME  sfun_decode_mavlink
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"

// System and Component IDs for MAVLink communication
#define SYS_ID 100
#define COMP_ID 200

#include "E:\rally\simulink_mavlink-master\include\mavlink\v2.0\common\mavlink.h"

#include "E:\rally\simulink_mavlink-master\include\sfun_decode_mavlink.h"

/* Function: mdlInitializeSizes ================================================
 * REQUIRED METHOD
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 */
static void mdlInitializeSizes(SimStruct *S)
{

    DECL_AND_INIT_DIMSINFO(inputDimsInfo);
    DECL_AND_INIT_DIMSINFO(outputDimsInfo);

    ssSetNumSFcnParams(S, 0);
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
        return; /* Parameter mismatch will be reported by Simulink */
    }

    if (!ssSetNumInputPorts(S, 1)) return;

    ssSetInputPortDirectFeedThrough(S, 0, 1);
    ssSetInputPortRequiredContiguous(S, 0, 1);
    ssSetInputPortDataType(S, 0, SS_UINT8);
    ssSetInputPortVectorDimension(S, 0, MAVLINK_MAX_PACKET_LEN);

	if (!ssSetNumOutputPorts(S, 3)) return;

	#if defined(MATLAB_MEX_FILE)
	if (ssGetSimMode(S) != SS_SIMMODE_SIZES_CALL_ONLY)
	{
		DTypeId dataTypeIdReg0;
		ssRegisterTypeFromNamedObject(S, BUS_NAME_ATTITUDE, &dataTypeIdReg0);
		if (dataTypeIdReg0 == INVALID_DTYPE_ID) return;
		ssSetOutputPortDataType(S, 0, dataTypeIdReg0);

		DTypeId dataTypeIdReg1;
		ssRegisterTypeFromNamedObject(S, BUS_NAME_ALTITUDE, &dataTypeIdReg1);
		if (dataTypeIdReg1 == INVALID_DTYPE_ID) return;
		ssSetOutputPortDataType(S, 1, dataTypeIdReg1);

		DTypeId dataTypeIdReg2;
		ssRegisterTypeFromNamedObject(S, BUS_NAME_VFR_HUD, &dataTypeIdReg2);
		if (dataTypeIdReg2 == INVALID_DTYPE_ID) return;
		ssSetOutputPortDataType(S, 2, dataTypeIdReg2);

	}
	#endif

	ssSetBusOutputObjectName(S, 0, (void *) BUS_NAME_ATTITUDE);
	ssSetBusOutputObjectName(S, 1, (void *) BUS_NAME_ALTITUDE);
	ssSetBusOutputObjectName(S, 2, (void *) BUS_NAME_VFR_HUD);

	ssSetOutputPortWidth(S, 0, 1);
	ssSetOutputPortWidth(S, 1, 1);
	ssSetOutputPortWidth(S, 2, 1);

	ssSetBusOutputAsStruct(S, 0, 1);
	ssSetBusOutputAsStruct(S, 1, 1);
	ssSetBusOutputAsStruct(S, 2, 1);

	ssSetOutputPortBusMode(S, 0, SL_BUS_MODE);
	ssSetOutputPortBusMode(S, 1, SL_BUS_MODE);
	ssSetOutputPortBusMode(S, 2, SL_BUS_MODE);

    ssSetNumSampleTimes(S, 1);

    /* specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);

    ssSetOptions(S, 0);   /* general options (SS_OPTION_xx) */

} /* end mdlInitializeSizes */


/* Function: mdlInitializeSampleTimes ==========================================
 * REQUIRED METHOD
 * Abstract:
 *    This function is used to specify the sample time(s) for your
 *    S-function. You must register the same number of sample times as
 *    specified in ssSetNumSampleTimes.
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    /* Register one pair for each sample time */
    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S);

} /* end mdlInitializeSampleTimes */

/* Function: mdlStart ==========================================================
 * Abstract:
 *    This function is called once at start of model execution. If you
 *    have states that should be initialized once, this is the place
 *    to do it.
 */
#define MDL_START
static void mdlStart(SimStruct *S)
{
    int_T *busInfo = (int_T *) malloc(2*NFIELDS_OUTPUT_BUS*sizeof(int_T));
    if(busInfo == NULL) {
      ssSetErrorStatus(S, "Memory allocation failure");
      return;
    }

	encode_businfo_attitude(S, busInfo, OFFSET_ATTITUDE);
	encode_businfo_altitude(S, busInfo, OFFSET_ALTITUDE);
	encode_businfo_vfr_hud(S, busInfo, OFFSET_VFR_HUD);

    ssSetUserData(S, busInfo);
} /* end mdlStart */


/* Function: mdlOutputs ========================================================
 * REQUIRED METHOD
 * Abstract:
 *    In this function, you compute the outputs of your S-function
 *    block.
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{

    int_T len_uvec = ssGetInputPortWidth(S, 0);
    const uint8_T* uvec = (uint8_T*) ssGetInputPortSignal(S, 0);

    mavlink_message_t msg;
    mavlink_status_t status;

    for (int uidx = 0; uidx < len_uvec; uidx++) {
      if(mavlink_parse_char(MAVLINK_COMM_0, uvec[uidx], &msg, &status)) {
        decode_mavlink_msg(S, &msg);
      }
    }

}

/* Function: mdlTerminate ======================================================
 * REQUIRED METHOD
 * Abstract:
 *    In this function, you should perform any actions that are necessary
 *    at the termination of a simulation.  For example, if memory was
 *    allocated in mdlStart, this is the place to free it.
 */
 static void mdlTerminate(SimStruct *S)
 {
     /* Free stored bus information */
     int_T *busInfo = (int_T *) ssGetUserData(S);
     if(busInfo != NULL) {
         free(busInfo);
     }
 }

/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif

