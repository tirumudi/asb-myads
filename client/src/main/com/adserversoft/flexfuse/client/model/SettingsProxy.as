package com.adserversoft.flexfuse.client.model
{
import com.adserversoft.flexfuse.client.model.vo.AdPlaceVO;
import com.adserversoft.flexfuse.client.model.vo.ServerRequestVO;
import com.adserversoft.flexfuse.client.model.vo.SettingsVO;

import flash.net.SharedObject;

import mx.collections.ArrayCollection;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.remoting.mxml.Operation;
import mx.rpc.remoting.mxml.RemoteObject;

import org.puremvc.as3.interfaces.IProxy;
import org.puremvc.as3.patterns.proxy.Proxy;

public class SettingsProxy extends Proxy implements IProxy
{
    public static const NAME:String = 'SettingsProxy';

    private var settingsRO:RemoteObject;
    private var _settings:SettingsVO = new SettingsVO;


    public function SettingsProxy()
    {
        super(NAME, new ArrayCollection);
        settingsRO = new RemoteObject();
        settingsRO.destination = "settings";
        settingsRO.requestTimeout = ApplicationConstants.REQUEST_TIMEOUT_SECONDS;

        settingsRO.getSettings.addEventListener("result", getSettingsResultHandler);
        settingsRO.getSettings.addEventListener("fault", faultHandler);

    }


    public function loadSettings():void {
        var userProxy:UserProxy = facade.retrieveProxy(UserProxy.NAME) as UserProxy;
        var settingsSO:SharedObject = SharedObject.getLocal("settings");
        var settingsProxy:SettingsProxy = facade.retrieveProxy(SettingsProxy.NAME) as SettingsProxy;
        var sr:ServerRequestVO = new ServerRequestVO(userProxy.authenticatedUser.sessionId, ApplicationConstants.VERSION, settingsProxy.settings.installationId);
        Operation(settingsRO.getSettings).arguments = new Array(sr, "en");
        settingsRO.getSettings(sr, "en");
    }

    private function getSettingsResultHandler(event:*):void
    {
        ApplicationConstants.application.enabled = true;
        if (event.result.result == ApplicationConstants.FAILURE) {
            sendNotification(ApplicationConstants.SERVER_FAULT, event.result);
        } else if (event.result.result == ApplicationConstants.SUCCESS) {
            var userProxy:UserProxy = facade.retrieveProxy(UserProxy.NAME) as UserProxy;
            settings = (ResultEvent)(event).result.resultingObject as SettingsVO;
            userProxy.authenticatedUser.sessionId = settings.sessionId;
            sendNotification(ApplicationConstants.SETTINGS_LOADED);

        } else {
            sendNotification(event.result.result);
        }
    }

    private function faultHandler(event:FaultEvent):void
    {
        sendNotification(ApplicationConstants.SERVER_FAULT, event);
    }


    public function getAdTag(ap:AdPlaceVO):Array {
        var arr:Array = new Array();
        if (ap.uid == null) {
            ap.uid = ApplicationConstants.getNewUid();
        }
        arr.push(ap.uid);
        var keyValueBufStr:String = "eventId=" + ApplicationConstants.GET_AD_TAG_SERVER_EVENT_TYPE + "&placeUid=" + ap.uid + "&instId=" + settings.installationId;
        arr.push( settings.adTag[0] +  ap.uid +settings.adTag[1] + settings.installationId + settings.adTag[2]);
//        arr.push(settings.adTag[0] + ap.width + settings.adTag[1] + ap.height + settings.adTag[2] + keyValueBufStr + settings.adTag[3] + ap.uid + settings.adTag[4] + settings.installationId + settings.adTag[5]);
        return arr;
    }

    public function get settings():SettingsVO {
        return _settings;
    }

    public function set settings(u:SettingsVO):void {
        this._settings = u;
    }

}
}