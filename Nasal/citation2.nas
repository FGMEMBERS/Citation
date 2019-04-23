aircraft.livery.init("Models/Liveries");
var cabin_door = aircraft.door.new("controls/cabin-door", 2);
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
    new : func(eng_num) {
        m = { parents : [JetEngine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg") or 6.72;

        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
# NOT the running property from YASim, which is always true and therefore useless.
        m.running =  m.eng.initNode("started",0,"BOOL");
        m.itt =      m.eng.getNode("itt-norm");
        m.n1 =       m.eng.getNode("n1",1);
        m.n2 =       m.eng.getNode("n2",1);
        m.fan =      m.eng.initNode("fan",0,"DOUBLE");
        m.turbine =  m.eng.initNode("turbine",0,"DOUBLE");
        m.fuel_pph = m.eng.initNode("fuel-flow_pph",0,"DOUBLE");
        m.fuel_gph = m.eng.initNode("fuel-flow-gph",0,"DOUBLE");
        m.fuel_out = m.eng.initNode("out-of-fuel",0,"BOOL");
        m.oil_psi  = m.eng.initNode("oil-pressure-psi",0,"DOUBLE");
        m.hyd_psi  = m.eng.initNode("hyd-pressure-psi",0,"DOUBLE");
        m.hyd_gpm  = m.eng.initNode("hyd-qty-gpm",0,"DOUBLE");

        m.ctrl = props.globals.getNode("controls/engines/engine["~eng_num~"]",1);
        m.throttle =       m.ctrl.initNode("throttle",0,"DOUBLE");
        m.throttle_real =  m.ctrl.initNode("throttle-real",0,"DOUBLE");
        m.throttle_lever = m.ctrl.initNode("throttle-lever",0,"DOUBLE");
        m.reverser =       m.ctrl.initNode("reverser",0,"BOOL");
        m.reverser_real =  m.ctrl.initNode("reverser-real",0,"BOOL");
        m.reverser_lever = m.ctrl.initNode("reverser-lever",0,"DOUBLE");
        m.cutoff =         m.ctrl.initNode("cutoff",0,"BOOL");
        m.cutoff_lock =    m.ctrl.initNode("cutoff-lock",0,"BOOL");
        m.ignition =       m.ctrl.initNode("ignition",0,"BOOL");
        m.ignition_auto =  m.ctrl.initNode("ignition-auto",0,"BOOL");
        m.starter =        m.ctrl.initNode("starter",0,"BOOL");

        m.reverser_pos =      props.globals.initNode("surface-positions/reverser-norm["~eng_num~"]",0,"DOUBLE");
        m.generator =         props.globals.initNode("controls/electric/engine["~eng_num~"]/generator-ready",0,"BOOL");
        m.generator_sw =      props.globals.initNode("controls/electric/engine["~eng_num~"]/generator-sw",0,"BOOL");
        m.starter_btn =       props.globals.initNode("controls/electric/engine["~eng_num~"]/starter-btn",0,"BOOL");
        m.boost_pump =        props.globals.initNode("controls/fuel/tank["~eng_num~"]/boost-pump",0,"BOOL");
        m.boost_pump_switch = props.globals.initNode("controls/fuel/tank["~eng_num~"]/boost-pump-switch",-1,"INT");

        m.Lfuel = setlistener(m.fuel_out, func m.shutdown(m.fuel_out.getValue()),0,0);
        m.Cut = setlistener(m.cutoff, func m.shutdown(m.cutoff.getValue()),0,0);

        m.autostart_in_progress = 0;
        m.cutoff_arm = 0;
        m.timer = 0;
        m.hobbs_timer = aircraft.timer.new ("engines/engine["~eng_num~"]/running-time-s");
        return m;
    },



#### update ####
    update : func{

        if (me.running.getBoolValue() and getprop("systems/electrical/outputs/main-right-xover/inst-flt-hr")) {
            if (!me.timer) {
                me.hobbs_timer.start ();
                me.timer = 1;
            }
        } else {
            if (me.timer) {
                me.hobbs_timer.stop ();
                me.timer = 0;
            }
        }

        var thr = me.throttle.getValue();
        var real = me.throttle_real.getValue();
        var lever = me.throttle_lever.getValue();

# cut-off position
        if (lever < 0.0) {
            lever += (thr - 0.01);
#           thr = 0.01;
            if (lever < -0.2) lever = -0.2;
            real = 0.0;
        }

        if (lever > -0.2 and lever < 0.0) {
            if (me.cutoff_lock.getBoolValue()) {
                if (lever < -0.1) lever = -0.2;
                else lever = 0.0;
            }
            else {
                me.cutoff_arm = 1;
            }
        }

        if (me.cutoff_arm) {
            if (lever > -0.005 or lever < -0.195) {
                me.cutoff_lock.setBoolValue(1);
                me.cutoff_arm = 0;
            }
        }
        else {
             if (me.cutoff.getBoolValue()) {
                if (lever > -0.195) { lever = -0.2; thr = 0.0; }
            }
            else {
                if (lever < -0.005) { lever = 0.0; }
            }
        }

        if (lever > -0.1) {
            me.cutoff.setBoolValue(0);
        }
        else {
            me.cutoff.setBoolValue(1);
        }

        if (lever >= 0.0) {
# if reverser moving
            if (me.reverser_pos.getValue() != nil and
                me.reverser_pos.getValue() > 0.0 and
                me.reverser_pos.getValue() < 1.0
            )
            {
                thr = 0.0;
                lever = 0.0;
                real = 0.0;
            }

# reverser deployed
            if (me.reverser.getBoolValue()) {
                lever = 0.0;
                if (me.running.getBoolValue()) {
                    real = thr * 0.92;
                } else {
                    real = 0.0;
                }
                me.reverser_lever.setValue(thr * 0.92 + 0.08);
            }
# reverser stowed
            else {
                if (!me.cutoff_lock.getBoolValue() and thr < 0.005) {
                    lever = -0.01;
                    thr = 0.0;
                    real = 0.0;
                }
                else {
                    lever = thr;
                    if (me.running.getBoolValue()) {
                        real = thr;
                    } else {
                        real = 0.0;
                    }
                }
                me.reverser_lever.setValue(0.0);
            }
        }

        me.throttle.setValue(thr);
        me.throttle_real.setValue(real);
        me.throttle_lever.setValue(lever);

# If the engine is running, simply copy n1 and n2 to fan and turbine.
        if(me.running.getBoolValue ()) {
            me.fan.setValue(me.n1.getValue());
            me.turbine.setValue(me.n2.getValue());
            if(getprop("controls/engines/grnd_idle")) thr *= 0.92;
        } else {
            var n1 = me.n1.getValue();
            var n2 = me.n2.getValue();
            var turbine = me.turbine.getValue();
            var fan = me.fan.getValue ();
            var scnds = 15;

            if (turbine > 20 and fan < 5) {
                me.starter_btn.setBoolValue (0);
                me.boost_pump.setBoolValue (0);
                me.ignition_auto.setBoolValue (0);
            }

# Engine not running. With starter spool up
            if(me.starter.getBoolValue()) {
                turbine += getprop ("sim/time/delta-sec") * n2 / scnds;

                if (turbine < n2) me.turbine.setValue (turbine);
                else me.turbine.setValue (n2);

                if (turbine > 9) {
# ignition will be automaticly turned on
                    if (!me.ignition.getBoolValue() ) { me.ignition_auto.setBoolValue(1); }

# if autostart is in progress push throttle forward
                    if (me.autostart_in_progress and me.cutoff.getBoolValue()) {
                        me.throttle.setValue (0.02);
                    }

                    if (me.ignition.getBoolValue() and me.boost_pump.getValue() and !me.cutoff.getBoolValue()) {
                        fan += getprop ("sim/time/delta-sec") * n1 / scnds;
                        me.fan.setValue (fan);

                        if (fan >= n1) { # declare victory
                            me.running.setBoolValue (1);
                            me.starter_btn.setBoolValue (0);
                            me.boost_pump.setBoolValue (0);
                            me.ignition_auto.setBoolValue (0);
                            me.generator.setBoolValue (1);
                            if (me.autostart_in_progress) {
                                me.generator_sw.setValue (1);
                                me.throttle.setValue (0.0);
                                me.autostart_in_progress = 0;
                            }
                        }
                    }
                    else {
                        if(fan > 0.0) {
                            fan -= getprop("sim/time/delta-sec") * 2;
                            if (fan < 0.0) fan = 0.0;
                            me.fan.setValue(fan);
                        }
                    }
                }
            }

# Engine not running. Without starter spool down
            else {
                # not running and not cycling up therefore we must be shutting down.
                me.ignition_auto.setBoolValue(0);
                if(turbine > 0.0) {
                    turbine -= getprop("sim/time/delta-sec") * 2;
                    if (turbine < 0.0) turbine = 0.0;
                    me.turbine.setValue(turbine);
                }
                if(fan > 0.0) {
                    fan -= getprop("sim/time/delta-sec") * 2;
                    if (fan < 0.0) fan = 0.0;
                    me.fan.setValue(fan);
                }
                if (me.autostart_in_progress) {
                    me.starter_btn.setBoolValue (1);
                }
            }
        }

        me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);

# fluid pump factor
        var factor = 1.0 - (me.turbine.getValue() * 0.01);
# oil pump
        var x = me.turbine.getValue() * 0.77;
        me.oil_psi.setValue(x);
# hydraulic pump
        var x = 1.0 - (factor * factor);
#        var x = (1.0 - (factor * factor)) * 60.0;
        me.hyd_psi.setValue(x * 60.0);
#        var x = (1.0 - (factor * factor)) * 2.5;
        me.hyd_gpm.setValue(x * 2.5);

##############
#    get_output_volts : func {
#        var x = 1.0 - me.percent.getValue();
#        var tmp = -(3.0 * x - 1.0);
#        var factor = (tmp * tmp * tmp * tmp * tmp + 32) / 32;
#        var output = me.ideal_volts * factor;
#        me.voltage.setValue(output);
#        return output;
##############


    },

    shutdown : func(b) {
        if (b) {
            me.running.setBoolValue (!b);
            me.generator.setBoolValue (0);
        }
    },

    autostart : func {
        me.autostart_in_progress = 1;
        me.boost_pump_switch.setValue (-1);
        me.cutoff_lock.setBoolValue (0);
    }
};



#################################################
var LHeng = JetEngine.new(0);
var RHeng = JetEngine.new(1);

#setlistener ("/controls/engines/engine[0]/cutoff", func (cutoff) {
#    LHeng.shutdown (cutoff.getBoolValue ());
#});
#
#setlistener ("/controls/engines/engine[1]/cutoff", func (cutoff) {
#    RHeng.shutdown (cutoff.getBoolValue ());
#});

var resetTrim = func(){
  setprop("/controls/flight/elevator-trim", 0);
  setprop("/controls/flight/rudder-trim", 0);
  setprop("/controls/flight/aileron-trim", 0);
  #print("All trim settings reset to 0...");
}

var resetControls = func() {
  setprop("/controls/flight/elevator", 0);
  setprop("/controls/flight/rudder", 0);
  setprop("/controls/flight/aileron", 0);
  #print("All flight controls reset to 0...");
}




setlistener("/sim/signals/fdm-initialized", func {

#  setprop ("/instrumentation/rmi/single-needle/selected-input", "VOR");
  switch_rmi("single-needle", 0);
#  setprop ("/instrumentation/rmi/double-needle/selected-input", "VOR");
  switch_rmi("double-needle", 1);


  if (getprop("/consumables/fuel/fuel_overlay") == 1) {
    # if we initialising a state overlay, then use pre-programmed fuel levels
    var fuelL= getprop("/consumables/fuel/fuel_overlay_0");
    var fuelR= getprop("/consumables/fuel/fuel_overlay_1");
    var totalFuel = fuelL + fuelR;
    print("Setting fuel levels to ", totalFuel, "lbs total.");

    # set some other properties
    if(getprop("/gear/gear_overlay") == 1) {
      print("forcing gear down!");
      setprop("/controls/gear/gear-down", 1);
    }

    # Try to get the preset numbers into the instruments
    #setprop("/instrumentation/rmi/single-needle/selected-input", getprop("/sim/presets/heading-deg"));

  }
  else {
    # Read old fuel levels
    var fuelL= getprop("/consumables/fuel/fuel-gal_us-0");
    var fuelR= getprop("/consumables/fuel/fuel-gal_us-1");
      # make sure we don't pass along a nil! (Most likely because this is our
      # first run with this model and have no previous value stored.)
    if(fuelL == nil or fuelR == nil) {
      fuelL = 371;
      fuelR = 371;
      print("No stored fuel-levels found. Setting to full.");
    }
    else {
      var totalFuel = fuelL + fuelR;
      print("Old fuel-levels restored. You have ", totalFuel, "lbs of fuel aboard.")
    }
  }
    # Override default "full tanks" with read values
  setprop("/consumables/fuel/tank[0]/level-gal_us", fuelL);
  setprop("/consumables/fuel/tank[1]/level-gal_us", fuelR);

  var batt_save = getprop("/systems/electrical/supplier/battery/percent-save");
  if(batt_save == nil) {
    batt_save = 1.0;
    print("Brand new battery installed.");
  }
  else {
    print("Battery restored. There are ", (batt_save * 100.0), "% charge left.");
  }
  setprop("/systems/electrical/supplier/battery/percent", batt_save);

  # on state overlays "taxi", "take-off" and "approach" we set the pressure automatically
  # since every checklist would agree to do this ahead of time!
  if (getprop("/environment/overlay") == 1) {
    var setAltimeterToPressure = maketimer(2, func() {
      setprop("/instrumentation/altimeter/setting-inhg", getprop("/environment/metar[0]/pressure-sea-level-inhg"));
      print("Altimeter set to ", getprop("/environment/metar[0]/pressure-sea-level-inhg"));
      setAltimeterToPressure.stop();
    });
    setAltimeterToPressure.singleShot = 1;
    setAltimeterToPressure.start();
  }

  # on states "cruise" and "approach" we set a heading from the launcher/CLI (--heading=123)
  if (getprop("/autopilot/heading_overlay")) {

    # start autopilot late, to avoid turbulent reactions from it
    var start_autopilot_in_air = maketimer(3, func(){
      print("Starting A/P ...");

      var overlay_name = getprop("/autopilot/overlay-name");
      if (overlay_name != nil) {
        if (overlay_name == "cruise") {
          var damper_mode = 1;
          var alt_mode = "altitude-hold";
          var hdg_mode = "true-heading-hold";
          var speed_mode = "speed-with-throttle";
          var bank_limit = 14;
          var target_speed = 220;
          var target_altitude = 36000;
        }
        if (overlay_name == "approach") {
          var damper_mode = 0;
          var alt_mode = "";
          var hdg_mode = "";
          var speed_mode = "";
          var bank_limit = 27;
          var target_speed = 100;
          var target_altitude = 3000;
        }

        setprop("/autopilot/locks/passive-mode", 1);
        setprop("/autopilot/settings/bank-limit", bank_limit);
        setprop("/autopilot/locks/yaw-damper", damper_mode);

        setprop("/autopilot/locks/speed", speed_mode);
        setprop("/autopilot/settings/target-speed-kt", target_speed);

        setprop("/autopilot/locks/altitude", alt_mode);
        setprop("/autopilot/settings/target-altitude-ft", target_altitude);

        var copyHeading = getprop("/sim/presets/heading-deg");
        setprop("/autopilot/locks/heading", hdg_mode);
        setprop("/autopilot/settings/true-heading-deg", copyHeading);
        print("HeadingOverlay requested... True-heading set to ", copyHeading, "°");
      }

      start_autopilot_in_air.stop();
    });
    start_autopilot_in_air.singleShot = 1;
    start_autopilot_in_air.start();
  }

  # override saved aircraft-data. It stores some useless data, and ignores some useful data.
  saveState.update_saveState();


#  resetTrim();
#  resetControls();
#
#  var resetFlightControls = maketimer(0.5, func() {
#    resetTrim();
#    resetControls();
#    resetFlightControls.stop();
#  });
#  resetFlightControls.singleShot = 1;
#  resetFlightControls.start();




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

setlistener("sim/model/autostart", func(strt) {
    if(strt.getBoolValue()){
        Startup();
    }else{
        Shutdown();
    }
},0,0);

var Startup = func{
    setprop("controls/electric/avionics-switch",1);
    setprop("controls/electric/battery-bus-switch",1);
    setprop("controls/electric/inverter-switch",1);
    setprop("controls/lighting/panel-lights-switch",1);
    setprop("controls/lighting/nav-lights-switch",1);
    setprop("controls/lighting/beacon-switch",1);
    setprop("controls/lighting/strobe-switch",1);
    setprop("controls/engines/throttle_idle",1);
    LHeng.autostart();
    RHeng.autostart();
}

var Shutdown = func{
    setprop("controls/electric/engine[0]/generator-ready",0);
    setprop("controls/electric/engine[1]/generator-ready",0);
    setprop("controls/electric/avionics-switch",0);
    setprop("controls/electric/battery-bus-switch",0);
    setprop("controls/lighting/panel-lights-switch",1);
    setprop("controls/lighting/nav-lights-switch",0);
    setprop("controls/lighting/beacon-switch",0);
    setprop("controls/lighting/strobe-switch",0);
    setprop("controls/engines/engine[0]/throttle",0);
    setprop("controls/engines/engine[1]/throttle",0);
}

controls.gearDown = func(v) {
    if (
        getprop("/systems/electrical/outputs/main-left/sys-gear-ctrl")
        and !getprop("/controls/electric/maingear-switch")
    ) {
        if (v < 0) {
            setprop("/controls/gear/gear-down", 0);
        }
        elsif (v > 0) {
            setprop("/controls/gear/gear-down", 1);
            setprop("/controls/gear/antiskid-test", getprop("/sim/time/elapsed-sec"));
        }
    }
}

controls.flapsDown = func(v) {
    var flap_pos=getprop("controls/flight/flaps") or 0;
    if (getprop("systems/electrical/outputs/main-left/sys-flap-ctrl") and getprop("systems/electrical/outputs/main-left/sys-flap-motor")) {
        flap_pos += v*0.125;
        if (flap_pos > 1.0) flap_pos = 1.0;
        if (flap_pos < 0.0) flap_pos = 0.0;
    }
    setprop("controls/flight/flaps",flap_pos);
}

var switch_rmi = func(needle, nav_number) {
  var selected_input = getprop ("/instrumentation/rmi/" ~ needle ~ "/selected-input");
  var dest_node = props.globals.getNode ("/instrumentation/rmi/" ~ needle ~ "/in-range", 1);
  dest_node.unalias ();
  if (selected_input == "ADF") {
    #print("RMI[", nav_number, "]: selected_input == ADF (", selected_input, ")");
    var source_node = props.globals.getNode ("/instrumentation/adf/in-range");
    dest_node.alias (source_node);
  }
  elsif (selected_input == "VOR") {
    #print("RMI[", nav_number, "]: selected_input == VOR (", selected_input, ")");
    var source_node = props.globals.getNode ("/instrumentation/nav[" ~ nav_number ~ "]/in-range");
    dest_node.alias (source_node);
  }
}

var hobbs_meter = {
    d0: props.globals.initNode ("instrumentation/hobbs-meter/digits0", 1, "INT"),
    d1: props.globals.initNode ("instrumentation/hobbs-meter/digits1", 1, "INT"),
    d2: props.globals.initNode ("instrumentation/hobbs-meter/digits2", 1, "INT"),
    d3: props.globals.initNode ("instrumentation/hobbs-meter/digits3", 1, "INT"),
    d4: props.globals.initNode ("instrumentation/hobbs-meter/digits4", 1, "INT"),
    e0: props.globals.initNode ("engines/engine[0]/running-time-s", 1, "DOUBLE"),
    e1: props.globals.initNode ("engines/engine[1]/running-time-s", 1, "DOUBLE"),
    update: func () {
        var left =  me.e0.getValue() or 0.0;
        var right = me.e1.getValue() or 0.0;
        var h = (left > right ? left : right) / 360.0; # tenths of hour, initially
        me.d0.setValue (math.mod (int (h), 10)); h = h / 10;
        me.d1.setValue (math.mod (int (h), 10)); h = h / 10;
        me.d2.setValue (math.mod (int (h), 10)); h = h / 10;
        me.d3.setValue (math.mod (int (h), 10)); h = h / 10;
        me.d4.setValue (math.mod (int (h), 10)); h = h / 10;
    },
};

var update_systems = func() {
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
    if (getprop ("autopilot/locks/passive-mode")) {
      var decision_height = getprop ("instrumentation/altimeter/decision-height");
      if (getprop ("position/altitude-agl-ft") < decision_height) {
        setprop ("autopilot/locks/passive-mode",0);
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

    # ugly hack! See Citation-II-common.xml line 711
    setprop("/consumables/fuel/fuel-gal_us-0", getprop("consumables/fuel/tank[0]/level-gal_us"));
    setprop("/consumables/fuel/fuel-gal_us-1", getprop("consumables/fuel/tank[1]/level-gal_us"));
    setprop("/systems/electrical/supplier/battery/percent-save", getprop("/systems/electrical/supplier/battery/percent"));

    hobbs_meter.update ();

    settimer(update_systems,0);
}

################################################################################
# Autopilot listeners

var passive_mode_listener = setlistener ("/autopilot/locks/passive-mode", func (passive_mode) {
    if (passive_mode.getBoolValue ()) {
        # When engaging the autopilot, engage wing leveler and pitch hold for
        # current pitch.  Set the target aileron and elevator commands to their
        # current position, to prevent brutal manoeuvers.
        setprop ("autopilot/internal/target-aileron", getprop ("controls/flight/aileron"));
        setprop ("autopilot/internal/target-elevator", getprop ("controls/flight/elevator"));
        setprop ("autopilot/locks/heading", "wing-leveler");
        setprop ("autopilot/locks/altitude", "pitch-hold");
        setprop ("autopilot/settings/target-pitch-deg", getprop ("orientation/pitch-deg"));
    }
    else {
        # When disengaging the autopilot, disengage all locks
        setprop ("autopilot/locks/heading", "");
        setprop ("autopilot/locks/altitude", "");
        setprop ("autopilot/locks/speed", "");
    }
}, 0, 0);

var autothrottle_listener = setlistener ("/autopilot/locks/speed", func (speed) {
    var speed_lock = speed.getValue ();
#    if (speed_lock == "speed-with-throttle") {
#      setprop("autopilot/settings/target-speed-kt", getprop ("instrumentation/airspeed-indicator/index-marker"));
#    }
    if (speed_lock == "speed-with-pitch-trim") { # only possible from the generic AP dialog
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
}

var drive_hsi_with_nav = func (hsi_node, nav_node) {
   var inputs = hsi_node.getChild ("inputs", 0, 1);
   alias_recursively (nav_node, inputs);
   var source_volts_node =
     props.globals.getNode ("/systems/electrical/outputs/nav[" ~ nav_node.getIndex () ~ "]");
   var dest_volts_node = hsi_node.getChild ("volts", 0, 1);
   dest_volts_node.unalias ();
   dest_volts_node.alias (source_volts_node);
}

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
