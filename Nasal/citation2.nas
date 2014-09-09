aircraft.livery.init("Aircraft/Citation/Models/Liveries");
var cabin_door = aircraft.door.new("/controls/cabin-door", 2);
var SndIn = props.globals.getNode("/sim/sound/Cvolume",1);
var SndOut = props.globals.getNode("/sim/sound/Ovolume",1);
var KPA = props.globals.initNode("instrumentation/altimeter/setting-kpa",101.3,"DOUBLE");
#Jet Engine Helper class 
# ie: var Eng = JetEngine.new(engine number);

var JetEngine = {
    new : func(eng_num){
        m = { parents : [JetEngine]};
        m.ITTlimit=8.9;
        m.fdensity = getprop("consumables/fuel/tank/density-ppg") or 6.72;
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.initNode("running",0,"BOOL");
        m.itt=m.eng.getNode("itt-norm");
        m.itt_c=m.eng.initNode("itt-celcius",0,"DOUBLE");
        m.n1 = m.eng.getNode("n1",1);
        m.n2 = m.eng.getNode("n2",1);
        m.fan = m.eng.initNode("fan",0,"DOUBLE");
        m.cycle_up = 0;
        m.engine_off=1;
        m.turbine = m.eng.initNode("turbine",0,"DOUBLE");
        m.throttle_lever = props.globals.initNode("controls/engines/engine["~eng_num~"]/throttle-lever",0,"DOUBLE");
        m.throttle = props.globals.initNode("controls/engines/engine["~eng_num~"]/throttle",0,"DOUBLE");
        m.ignition = props.globals.initNode("controls/engines/engine["~eng_num~"]/ignition",0,"DOUBLE");
        m.cutoff = props.globals.initNode("controls/engines/engine["~eng_num~"]/cutoff",1,"BOOL");
        m.fuel_out = props.globals.initNode("engines/engine["~eng_num~"]/out-of-fuel",0,"BOOL");
        m.starter = props.globals.initNode("controls/engines/engine["~eng_num~"]/starter",0,"BOOL");
        m.fuel_pph=m.eng.initNode("fuel-flow_pph",0,"DOUBLE");
        m.fuel_gph=m.eng.initNode("fuel-flow-gph");
        m.hpump=props.globals.initNode("systems/hydraulics/pump-psi["~eng_num~"]",0,"DOUBLE");

        m.Lfuel = setlistener(m.fuel_out, func m.shutdown(m.fuel_out.getValue()),0,0);
        m.CutOff = setlistener(m.cutoff, func (ct){m.engine_off=ct.getValue()},1,0);
    return m;
    },
#### update ####
    update : func{
        var thr = me.throttle.getValue();
        if(!me.engine_off){
            me.fan.setValue(me.n1.getValue());
            me.turbine.setValue(me.n2.getValue());
            if(getprop("controls/engines/grnd_idle"))thr *=0.92;
            me.throttle_lever.setValue(thr);
        }else{
            me.throttle_lever.setValue(0);
            if(me.starter.getBoolValue()){
                if(me.cycle_up == 0)me.cycle_up=1;
            }
            if(me.cycle_up>0){
                me.spool_up(15);
            }else{
                var tmprpm = me.fan.getValue();
                if(tmprpm > 0.0){
                    tmprpm -= getprop("sim/time/delta-sec") * 2;
                    me.fan.setValue(tmprpm);
                    me.turbine.setValue(tmprpm);
                }
            }
        }
        
        me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);
        var hpsi =me.fan.getValue();
        if(hpsi>60)hpsi = 60;
        me.hpump.setValue(hpsi);
        me.itt_c.setValue(me.fan.getValue() * me.ITTlimit);
    },

    spool_up : func(scnds){
        if(me.engine_off){
        var n1=me.n1.getValue() ;
        var n1factor = n1/scnds;
        var n2=me.n2.getValue() ;
        var n2factor = n2/scnds;
        var tmprpm = me.fan.getValue();
            tmprpm += getprop("sim/time/delta-sec") * n1factor;
            var tmprpm2 = me.turbine.getValue();
            tmprpm2 += getprop("sim/time/delta-sec") * n2factor;
            me.fan.setValue(tmprpm);
            me.turbine.setValue(tmprpm2);
            if(tmprpm >= me.n1.getValue()){
                var ign=1-me.ignition.getValue();
                me.cutoff.setBoolValue(ign);
                me.cycle_up=0;
            }
        }
    },

    shutdown : func(b){
        if(b!=0){
            me.cutoff.setBoolValue(1);
        }
    }

};
#################################################
var LHeng= JetEngine.new(0);
var RHeng= JetEngine.new(1);


setlistener("/sim/signals/fdm-initialized", func {
    SndIn.setDoubleValue(0.75);
    SndOut.setDoubleValue(0.15);
    settimer(update_systems,2);
});

setlistener("/sim/current-view/internal", func(vw){
    if(vw.getBoolValue()){
        SndIn.setDoubleValue(0.75);
        SndOut.setDoubleValue(0.10);
    }else{
        SndIn.setDoubleValue(0.10);
        SndOut.setDoubleValue(0.75);
    }
},1,0);

setlistener("/instrumentation/altimeter/setting-inhg", func(inhg){
    var kpa = inhg.getValue() * 3.386389;
     KPA.setValue(kpa);
},1,0);

setlistener("sim/model/autostart", func(strt){
    if(strt.getBoolValue()){
        Startup();
    }else{
        Shutdown();
    }
},0,0);

var Startup = func{
    setprop("controls/electric/engine[0]/generator",1);
    setprop("controls/electric/engine[1]/generator",1);
    setprop("controls/electric/avionics-switch",1);
    setprop("controls/electric/battery-switch",1);
    setprop("controls/electric/inverter-switch",1);
    setprop("controls/lighting/instrument-lights",1);
    setprop("controls/lighting/nav-lights",1);
    setprop("controls/lighting/beacon",1);
    setprop("controls/lighting/strobe",1);
    setprop("controls/engines/engine[0]/cutoff",0);
    setprop("controls/engines/engine[1]/cutoff",0);
    setprop("controls/engines/engine[0]/ignition",1);
    setprop("controls/engines/engine[1]/ignition",1);
    setprop("engines/engine[0]/running",1);
    setprop("engines/engine[1]/running",1);
    setprop("controls/engines/throttle_idle",1);
}

var Shutdown = func{
    setprop("controls/electric/engine[0]/generator",0);
    setprop("controls/electric/engine[1]/generator",0);
    setprop("controls/electric/avionics-switch",0);
    setprop("controls/electric/battery-switch",0);
    setprop("controls/electric/inverter-switch",0);
    setprop("controls/lighting/instrument-lights",1);
    setprop("controls/lighting/nav-lights",0);
    setprop("controls/lighting/beacon",0);
    setprop("controls/lighting/strobe",0);
    setprop("controls/engines/engine[0]/cutoff",1);
    setprop("controls/engines/engine[1]/cutoff",1);
    setprop("controls/engines/engine[0]/ignition",0);
    setprop("controls/engines/engine[1]/ignition",0);
    setprop("engines/engine[0]/running",0);
    setprop("engines/engine[1]/running",0);
}

controls.gearDown = func(v) {
    if (v < 0) {
        if(!getprop("gear/gear[1]/wow"))setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}

controls.flapsDown = func(v) {
    var flap_pos=getprop("controls/flight/flaps") or 0;
    flap_power = getprop("systems/electrical/outputs/flaps") or 0;
    if ( flap_power > 5) {
        flap_pos += v*0.125;
    }
    setprop("controls/flight/flaps",flap_pos);
}

var update_systems = func{
    LHeng.update();
    RHeng.update();
    if(getprop("velocities/airspeed-kt")>40)cabin_door.close();
    if(getprop("controls/flight/speedbrake")>0){
        if(getprop("engines/engine/turbine")>85 or getprop("engines/engine/turbine")>85)setprop("controls/flight/speedbrake",0);
    }
    if(!getprop("autopilot/locks/passive-mode")){
        if(getprop("position/altitude-agl-ft") <200) setprop("autopilot/locks/passive-mode",1); 
    }

    if(getprop("autopilot/settings/gs-arm")){
        if(getprop("instrumentation/nav/gs-in-range")){
            var GS = getprop("instrumentation/nav/gs-needle-deflection");
            if(GS < 0.05 and GS > -0.05){
                setprop("autopilot/settings/gs-arm",0);
                setprop("autopilot/locks/altitude","gs1-hold");
            }
        }
    }

    if(getprop("autopilot/settings/nav-arm")){
        var NAV = getprop("instrumentation/nav/heading-needle-needle");
        if(NAV < 0.7 and NAV > -0.7){
            setprop("autopilot/settings/nav-arm",0);
            setprop("autopilot/locks/heading","nav-hold");
        } 
    }

    settimer(update_systems,0);
}
