;*=====================================================================*/
;*    .../project/bigloo/bigloo/api/mqtt/src/Misc/make_lib.scm         */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Tue Nov  6 15:09:37 2001                          */
;*    Last change :  Sun Mar 13 06:56:47 2022 (serrano)                */
;*    Copyright   :  2001-22 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    The module used to build the heap file and the _e library        */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __mqtt_makelib
   
   (import __mqtt_mqtt
	   __mqtt_server
	   __mqtt_client)
   
   (eval   (export-all)))
