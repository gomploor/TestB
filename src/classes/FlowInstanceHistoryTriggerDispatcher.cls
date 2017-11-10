/**
* @description This class extends the TriggerDispatcherBase to provide the dispatching functionality for the trigger actions 
*               on the Case object. The event handlers support allowing and preventing actions for reentrant scenarios. 
*               This is controlled by the flag isBeforeXxxxx and isAfterXxxxx member variables. These variables need to be set
*               to true before invoking the handlers and set to false after the invocation of the handlers. Resetting is MUST
*               as otherwise unit tests MAY fail. The actual actions should be placed in the handlers (in a separate class).
*/
public without sharing class FlowInstanceHistoryTriggerDispatcher extends TriggerDispatcherBase{
    
     /** 
    * @description  Called by the trigger framework to carry out the actions before the records are inserted. 
    *               If there is an existing call running on the same context, the rentrant call will utilize
    *               the handler that was created in the original call.-
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting inserted.-
    */
    public virtual override void afterUpdate(TriggerParameters tp) {
        execute(new FIHAfterUpdateTriggerHandler(), tp, TriggerParameters.TriggerEvent.afterUpdate);
    }
   
}