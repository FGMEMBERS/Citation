aircraft.livery.init("Models/Liveries");
var cabin_door = aircraft.door.new("/controls/cabin-door", 2);
var baggage_door_front_left = aircraft.door.new("controls/baggage-door-front-left",2);
var baggage_door_front_right = aircraft.door.new("controls/baggage-door-front-right",2);
var baggage_door_aft = aircraft.door.new("controls/baggage-door-aft",2);
var SndIn = props.globals.getNode("/sim/sound/Cvolume",1);
var SndOut = props.globals.getNode("/sim/sound/Ovolume",1);
var KPA = props.globals.initNode("instrumentation/altimeter/setting-kpa",101.3,"DOUBLE");

#Jet Engine Helper class
# ie: var Eng = JetEngine.new(engine number);

# The jet engines in YASim are always on and cannot be turned off except by
# fuel starvation.  We want to be able to turn our engines on (spool up) and
# off at will, so our flightdeck does not display /engines/engine[*]/n1 and n2
# from YASim, instead they show /engines/engine[*]/fan and turbine,
# respectively.  Both fan and turbine start at zero and will spool up to reach
# n1 and n2; at that point we declare the engine to be running.

var JetEngine = {
    new : func(eng_num){
        m = { parents : [JetEngine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg") or 6.72;
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.initNode("started",0,"BOOL");
        # NOT the running property from YASim, which is always true and therefore useless.
        m.itt=m.eng.getNode("itt-norm");
        m.n1 = m.eng.getNode("n1",1);
        m.n2 = m.eng.getNode("n2",1);
        m.fan = m.eng.initNode("fan",0,"DOUBLE");
        m.cycle_up = 0;
        m.turbine = m.eng.initNode("turbine",0,"DOUBLE");
        m.throttle_lever = props.globals.initNode("controls/engines/engine["~eng_num~"]/throttle-lever",0,"DOUBLE");
        m.throttle = props.globals.initNode("controls/engines/engine["~eng_num~"]/throttle",0,"DOUBLE");
        m.ignition = props.globals.initNode("controls/engines/engine["~eng_num~"]/ignition",0,"BOOL");
        m.fuel_out = props.globals.initNode("engines/engine["~eng_num~"]/out-of-fuel",0,"BOOL");
        m.starter = props.globals.initNode("controls/engines/engine["~eng_num~"]/starter",0,"BOOL");
        m.fuel_pph=m.eng.initNode("fuel-flow_pph",0,"DOUBLE");
        m.fuel_gph=m.eng.initNode("fuel-flow-gph");
        m.fuel_pump_boost =
            props.globals.initNode ("controls/fuel/tank["~eng_num~"]/boost-pump",
                                    0,
                                    "BOOL");
        m.hpump=props.globals.initNode("systems/hydraulics/pump-psi["~eng_num~"]",0,"DOUBLE");

        m.Lfuel = setlistener(m.fuel_out, func m.shutdown(m.fuel_out.getValue()),0,0);
    return m;
    },
#### update ####
    update : func{
        var thr = me.throttle.getValue();
        if(me.running.getBoolValue ()){
            # If the engine is running, simply copy n1 and n2 to fan and turbine.
            me.fan.setValue(me.n1.getValue());
            me.turbine.setValue(me.n2.getValue());
            if(getprop("controls/engines/grnd_idle"))thr *=0.92;
            me.throttle_lever.setValue(thr);
        }else{
            # Engine not running.  Decide whether to start it or not.
            me.throttle_lever.setValue(0);
            if(me.starter.getBoolValue() # and it has electricity:
               and (getprop ("/systems/electrical/outputs/bus/left") > 20.0
                    or getprop ("/systems/electrical/outputs/bus/right") > 20.0))
            {
                if(me.cycle_up == 0)me.cycle_up=1;
            }
            if(me.cycle_up>0){
                me.spool_up (15); # it will take this many seconds to spool up.
            }else{
                # not running and not cycling up therefore we must be shutting down.
                var tmprpm = me.fan.getValue();
                if(tmprpm > 0.0){
                    tmprpm -= getprop("sim/time/delta-sec") * 2;
                    if (tmprpm <= 0.0) { tmprpm = 0.0; }
                    me.fan.setValue(tmprpm);
                    me.turbine.setValue(tmprpm);
                }
            }
        }

        me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);
        var hpsi =me.fan.getValue();
        if(hpsi>60)hpsi = 60;
        me.hpump.setValue(hpsi);
    },

    spool_up : func(scnds) {
        # We spool the turbine up.  If the turbine reaches a threshold and
        # ignition and the fuel boost pump are both ON, we then spool the fan
        # up.
        var n1 = me.n1.getValue();
        var n2 = me.n2.getValue();
        var turbine = me.turbine.getValue()
            + getprop ("sim/time/delta-sec") * n2 / scnds;
        if (turbine < n2) { me.turbine.setValue (turbine); }
        else { me.turbine.setValue (n2); }

        if (turbine > 20
            and me.ignition.getValue ()
            and me.fuel_pump_boost.getValue () # and it has electricity:
            and (getprop ("/systems/electrical/outputs/bus/left") > 20.0
                 or getprop ("/systems/electrical/outputs/bus/right") > 20.0))
        {
            var fan = me.fan.getValue ()
                + getprop ("sim/time/delta-sec") * n1 / scnds;
            me.fan.setValue (fan);
            if (fan >= n1) { # declare victory
                me.cycle_up = 0;
                me.starter.setBoolValue (0);
                me.running.setBoolValue (1);
            }
        }
    },

    shutdown : func(b){
        if (!b) {
            me.running.setBoolValue (b);
        }
    }

};



#################################################
var LHeng= JetEngine.new(0);
var RHeng= JetEngine.new(1);

setlistener ("/controls/engines/engine[0]/ignition", func (ignition) {
    LHeng.shutdown (ignition.getBoolValue ());
});

setlistener ("/controls/engines/engine[1]/ignition", func (ignition) {
    RHeng.shutdown (ignition.getBoolValue ());
});

setlistener ("/sim/signals/fdm-initialized", func {

  setprop ("/instrumentation/rmi/single-needle/selected-input", "VOR");
  switch_rmi ("single-needle", 0);

  if (getprop("/consumables/fuel/fuel_overlay") == 1) {
    # if we initialising a state overlay, then use pre-programmed fuel levels
    var fuelL= getprop("/consumables/fuel/fuel_overlay_0");
    var fuelR= getprop("/consumables/fuel/fuel_overlay_1");

    # set some other properties
    if(getprop("/gear/gear_overlay") == 1) {
      print("forcing gear down!");
      setprop("/controls/gear/gear-down", 1);
    }

    # Try to get the preset numbers into the instruments
    setprop("/instrumentation/rmi/single-needle/selected-input", getprop("/sim/presets/heading-deg"));

  }
  else {
    # Read old fuel levels
    var fuelL= getprop("/consumables/fuel/fuel-gal_us-0");
    var fuelR= getprop("/consumables/fuel/fuel-gal_us-1");
      # make sure we don't pass along a nil! (Most likely because this is our
      # first run with this model and have no previous value stored.)
    if(fuelL == nil) { fuelL = 371; }
    if(fuelR == nil) { fuelR = 371; }
  }
    # Override default "full tanks" with read values
  setprop("/consumables/fuel/tank[0]/level-gal_us", fuelL);
  setprop("/consumables/fuel/tank[1]/level-gal_us", fuelR);



  # start looking for weight and gear-compression
  var WFinitAllDone = 0;
  var WFinitWeight = 0;
  var WFinitCompL = 0;
  var WFinitCompR = 0;
  var iterationCounter = 0;

  var WFinitChecker = maketimer(5, func() {

    # Initial values of weight and corresponding gear-compression.
    # Used in Models/load-factor-filter.xml to calculate wingflex

    var initialWeight = getprop("yasim/gross-weight-lbs");
    var correspondingGearCompressionL = getprop("gear/gear[1]/compression-norm");
    var correspondingGearCompressionR = getprop("gear/gear[2]/compression-norm");

    if (initialWeight != nil and iterationCounter > 1) {
      WFinitWeight = 1;

    }
    if (correspondingGearCompressionL != nil and iterationCounter > 1) {
      WFinitCompL = 1;
    }
    if (correspondingGearCompressionR != nil and iterationCounter > 1) {
      WFinitCompR = 1;
    }

    if (WFinitWeight == 1 and WFinitCompL == 1 and WFinitCompR == 1) { WFinitAllDone = 1; }

    iterationCounter = iterationCounter + 1;

    if (WFinitAllDone == 1 and iterationCounter > 1) {
      var averageGearCompression = (correspondingGearCompressionL + correspondingGearCompressionR) / 2;
      setprop("sim/systems/wingflexer/initialGearCompression", averageGearCompression);
      setprop("sim/systems/wingflexer/initialWeight", initialWeight);
      setprop("sim/systems/wingflexer/initComplete", 1);
      WFinitChecker.stop();
    }
    else { WFinitChecker.restart(5); }
  });
  WFinitChecker.singleShot = 1;
  WFinitChecker.start();



  SndIn.setDoubleValue(0.75);
  SndOut.setDoubleValue(0.15);
  settimer(update_systems,2);
  # Initially drive the pilot's HSI with NAV1 and copilot's with NAV2
  drive_hsi_with_nav (props.globals.getNode ("/instrumentation/hsi[0]"),
                      props.globals.getNode ("/instrumentation/nav[0]"));
  drive_hsi_with_nav (props.globals.getNode ("/instrumentation/hsi[1]"),
                      props.globals.getNode ("/instrumentation/nav[1]"));
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
    setprop("controls/electric/battery-bus-switch",1);
    setprop("controls/electric/inverter-switch",1);
    setprop("controls/lighting/instrument-lights",1);
    setprop("controls/lighting/nav-lights",1);
    setprop("controls/lighting/beacon",1);
    setprop("controls/lighting/strobe",1);
    setprop("controls/engines/engine[0]/ignition",1);
    setprop("controls/engines/engine[1]/ignition",1);
    setprop("controls/fuel/tank[0]/boost-pump-switch",1);
    setprop("controls/fuel/tank[1]/boost-pump-switch",1);
    setprop("controls/engines/engine[0]/starter",1);
    setprop("controls/engines/engine[1]/starter",1);
    setprop("controls/engines/throttle_idle",1);
}

var Shutdown = func{
    setprop("controls/electric/engine[0]/generator",0);
    setprop("controls/electric/engine[1]/generator",0);
    setprop("controls/electric/avionics-switch",0);
    setprop("controls/electric/battery-bus-switch",0);
    setprop("controls/lighting/instrument-lights",1);
    setprop("controls/lighting/nav-lights",0);
    setprop("controls/lighting/beacon",0);
    setprop("controls/lighting/strobe",0);
    setprop("controls/engines/engine[0]/ignition",0);
    setprop("controls/engines/engine[1]/ignition",0);
    setprop("controls/fuel/tank[0]/boost-pump-switch",0);
    setprop("controls/fuel/tank[1]/boost-pump-switch",0);
    setprop("engines/engine[0]/running",0);
    setprop("engines/engine[1]/running",0);
}

controls.gearDown = func(v) {
    if (v < 0 and getprop("controls/electric/circuit-breakers/bus-left/cb-gear-ctl")) {
        if(!getprop("gear/gear[1]/wow")) {
          setprop("/controls/gear/gear-down", 0);
        }
    } elsif (v > 0 and getprop("controls/electric/circuit-breakers/bus-left/cb-gear-ctl")) {
       setprop("/controls/gear/gear-down", 1);
    }
}

controls.flapsDown = func(v) {
    var flap_pos=getprop("controls/flight/flaps") or 0;
    if (getprop("systems/electrical/outputs/bus/left") > 20 and getprop("controls/electric/circuit-breakers/bus-left/cb-flap-ctl") and getprop("controls/electric/circuit-breakers/bus-left/cb-flap-motor")) {
        flap_pos += v*0.125;
    }
    setprop("controls/flight/flaps",flap_pos);
}

var switch_rmi = func (needle, nav_number) {
  var selected_input = getprop ("/instrumentation/rmi/"~needle~"/selected-input");
  var dest_node = props.globals.getNode ("/instrumentation/rmi/"~needle~"/in-range", 1);
  dest_node.unalias ();
  if (selected_input == "ADF") {
    var source_node = props.globals.getNode ("/instrumentation/adf/in-range");
    dest_node.alias (source_node);
  }
  elsif (selected_input == "VOR") {
    var source_node = props.globals.getNode ("/instrumentation/nav[" ~ nav_number ~ "]/in-range");
    dest_node.alias (source_node);
  }
}

var update_systems = func{
    LHeng.update();
    RHeng.update();
    if(getprop("velocities/groundspeed-kt")>10) {
        cabin_door.close();
        baggage_door_aft.close();
        baggage_door_front_left.close();
        baggage_door_front_right.close();
    }
    if(getprop("controls/flight/speedbrake")>0) {
        if(getprop("engines/engine[0]/turbine")>85
        or getprop("engines/engine[1]/turbine")>85) {
           setprop("controls/flight/speedbrake-switch", 0);
        }
    }

    # Disengage the autopilot when reaching decision height selected on the radio
    # altimeter or 500ft, whichever is highest.
    if (!getprop ("autopilot/locks/passive-mode")) {
      var decision_height = getprop ("instrumentation/altimeter/decision-height");
      if (decision_height < 500) { decision_height = 500; }
      if (getprop ("position/altitude-agl-ft") < decision_height) {
        setprop ("autopilot/locks/passive-mode",1);
        setprop ("autopilot/locks/altitude", "");
        setprop ("autopilot/locks/heading", "");
        setprop ("autopilot/locks/yaw-damper", 0);
        setprop ("autopilot/locks/speed", "");
      }
    }

    if(getprop("autopilot/settings/gs1-arm")){
        if(getprop("instrumentation/nav/gs-in-range")){
            var GS = getprop("instrumentation/nav/gs-needle-deflection");
            if(-3.5 <= GS and GS <= 0.0){
                setprop("autopilot/settings/gs1-arm", 0);
                setprop("autopilot/locks/altitude","gs1-hold");
            }
        }
    }

    setprop("/consumables/fuel/fuel-gal_us-0", getprop("/consumables/fuel/tank[0]/level-gal_us"));
    setprop("/consumables/fuel/fuel-gal_us-1", getprop("/consumables/fuel/tank[1]/level-gal_us"));
    settimer(update_systems,0);
}

################################################################################
# Autopilot listeners

var passive_mode_listener = setlistener ("/autopilot/locks/passive-mode", func (passive_mode) {
    if (passive_mode.getBoolValue ()) {
        # When engaging passive mode, disengage all locks
        setprop ("autopilot/locks/heading", "");
        setprop ("autopilot/locks/altitude", "");
        setprop ("autopilot/locks/speed", "");
    }
    else {
        # When engaging the autopilot, engage wing leveler and pitch hold for
        # current pitch.  Set the target aileron and elevator commands to their
        # current position, to prevent brutal manoeuvers.
        setprop ("autopilot/internal/target-aileron",
                 getprop ("controls/flight/aileron"));
        setprop ("autopilot/internal/target-elevator",
                 getprop ("controls/flight/elevator"));
        setprop ("autopilot/locks/heading", "wing-leveler");
        setprop ("autopilot/locks/altitude", "pitch-hold");
        setprop ("autopilot/settings/target-pitch-deg", getprop ("orientation/pitch-deg"));
    }
}, 0, 0);

var autothrottle_listener = setlistener ("/autopilot/locks/speed", func (speed) {
    var speed_lock = speed.getValue ();
    if (speed_lock == "speed-with-throttle") {
        setprop("autopilot/settings/target-speed-kt", getprop ("velocities/airspeed-kt"));
    }
    elsif (speed_lock == "speed-with-pitch-trim") { # only possible from the generic AP dialog
        screen.log.write ("speed-with-pitch-trim is not supported on this aircraft.");
    }
}, 0, 0);



var alias_recursively = func (source, dest) { # source and dest must be nodes not names
   var children = source.getChildren ();
   if (size (children) == 0) {
      dest.unalias ();
      dest.alias (source);
   }
   foreach (var child; children) {
      var dest_node = dest.getChild (child.getName (), child.getIndex (), 1);
      alias_recursively (child, dest_node);
   }
};

var drive_hsi_with_nav = func (hsi_node, nav_node) {
   var inputs = hsi_node.getChild ("inputs", 0, 1);
   alias_recursively (nav_node, inputs);
   var source_volts_node =
     props.globals.getNode ("/systems/electrical/outputs/nav[" ~ nav_node.getIndex () ~ "]");
   var dest_volts_node = hsi_node.getChild ("volts", 0, 1);
   dest_volts_node.unalias ();
   dest_volts_node.alias (source_volts_node);
};

var pilot_hsi_listener =
  setlistener ("/instrumentation/hsi[0]/selected-nav", func (selected_nav) {
   var hsi_node = props.globals.getNode ("/instrumentation/hsi[0]");
   var nav_node = props.globals.getNode ("/instrumentation/nav[" ~ selected_nav.getValue () ~ "]");
   drive_hsi_with_nav (hsi_node, nav_node);
}, 0, 0);

var copilot_hsi_listener =
  setlistener ("/instrumentation/hsi[1]/selected-nav", func (selected_nav) {
   var hsi_node = props.globals.getNode ("/instrumentation/hsi[1]");
   var nav_node = props.globals.getNode ("/instrumentation/nav[" ~ selected_nav.getValue () ~ "]");
   drive_hsi_with_nav (hsi_node, nav_node);
}, 0, 0);
