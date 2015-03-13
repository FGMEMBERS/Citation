####    jet engine electrical system    ####
####    Syd Adams  -  modified from Curt's original electrical code ####
var ammeter_ave = 0.0;
var Lbus = props.globals.initNode("/systems/electrical/left-bus",0,"DOUBLE");
var Rbus = props.globals.initNode("/systems/electrical/right-bus",0,"DOUBLE");
var ACbus = props.globals.initNode("/systems/electrical/ac-volts",0,"DOUBLE");
var Amps = props.globals.initNode("/systems/electrical/amps",0,"DOUBLE");
var EXT  = props.globals.initNode("/controls/electric/external-power",0,"DOUBLE");
var XTie  = props.globals.initNode("/systems/electrical/xtie",0,"BOOL");
var inverter_switch = props.globals.initNode ("controls/electric/inverter-switch", 1, "BOOL");

var lbus_volts = 0.0;
var rbus_volts = 0.0;

var lbus_input=[];
var lbus_output=[];
var lbus_load=[];

var rbus_input=[];
var rbus_output=[];
var rbus_load=[];

var avbus_input=[];
var avbus_output=[];
var avbus_load=[];

var lights_input=[];
var lights_output=[];
var lights_load=[];

var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("controls/lighting/strobe-state", [0.05, 1.30], strobe_switch);
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("controls/lighting/beacon-state", [1.0, 1.0], beacon_switch);

####################################################

var Battery = {
    new : func(swtch,vlt,amp,hr,chp,cha){
    m = { parents : [Battery] };
            m.switch = props.globals.getNode(swtch,1);
            m.switch.setBoolValue(0);
            m.ideal_volts = vlt;
            m.ideal_amps = amp;
            m.amp_hours = hr;
            m.charge_percent = chp;
            m.charge_amps = cha;
    return m;
    },

    apply_load : func(load,dt) {
        if(me.switch.getValue()){
        var amphrs_used = load * dt / 3600.0;
        var percent_used = amphrs_used / me.amp_hours;
        me.charge_percent -= percent_used;
        if ( me.charge_percent < 0.0 ) {
            me.charge_percent = 0.0;
        } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
        }
        var output =me.amp_hours * me.charge_percent;
        return output;
        }else return 0;
    },

    get_output_volts : func {
        if(me.switch.getValue()){
        var x = 1.0 - me.charge_percent;
        var tmp = -(3.0 * x - 1.0);
        var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
        var output =me.ideal_volts * factor;
        return output;
        }else return 0;
    },

    get_output_amps : func {
        if(me.switch.getValue()){
        var x = 1.0 - me.charge_percent;
        var tmp = -(3.0 * x - 1.0);
        var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
        var output =me.ideal_amps * factor;
        return output;
        }else return 0;
    }
};

########################################################

# var alternator = Alternator.new(num,switch,rpm_source,rpm_threshold,volts,amps);
var Alternator = {
    new : func (num,switch,src,thr,vlt,amp){
        m = { parents : [Alternator] };
        m.switch =  props.globals.getNode(switch,1);
        m.switch.setBoolValue(0);
        m.meter =  props.globals.getNode("systems/electrical/gen-load["~num~"]",1);
        m.meter.setDoubleValue(0);
        m.gen_output =  props.globals.getNode("engines/engine["~num~"]/amp-v",1);
        m.gen_output.setDoubleValue(0);
        m.meter.setDoubleValue(0);
        m.rpm_source =  props.globals.getNode(src,1);
        m.rpm_threshold = thr;
        m.ideal_volts = vlt;
        m.ideal_amps = amp;
        return m;
    },

    apply_load : func(load) {
        var cur_volt=me.gen_output.getValue();
        var cur_amp=me.meter.getValue();
        if(cur_volt >1){
            var factor=1/cur_volt;
            gout = (load * factor);
            if(gout>1)gout=1;
        }else{
            gout=0;
        }
        me.meter.setValue(gout);
    },

    get_output_volts : func {
        var out = 0;
        if(me.switch.getBoolValue()){
            var factor = me.rpm_source.getValue() / me.rpm_threshold or 0;
            if ( factor > 1.0 )factor = 1.0;
            var out = (me.ideal_volts * factor);
        }
        me.gen_output.setValue(out);
        return out;
    },

    get_output_amps : func {
        var ampout =0;
        if(me.switch.getBoolValue()){
            var factor = me.rpm_source.getValue() / me.rpm_threshold or 0;
            if ( factor > 1.0 ) {
                factor = 1.0;
            }
            ampout = me.ideal_amps * factor;
        }
        return ampout;
    }
};

#####################################################

var battery = Battery.new("/controls/electric/battery-switch",24,30,34,1.0,7.0);
var alternator1 = Alternator.new(0,"controls/electric/engine[0]/generator","/engines/engine[0]/turbine",20.0,28.0,60.0);
var alternator2 = Alternator.new(1,"controls/electric/engine[1]/generator","/engines/engine[1]/turbine",20.0,28.0,60.0);

setlistener("/sim/signals/fdm-initialized", func {
    init_switches();
    settimer(update_electrical,5);
    print("Electrical System ... ok");
});

var init_switches = func{

    setprop("controls/lighting/engines-norm",0.8);
    props.globals.initNode("controls/electric/ammeter-switch",0,"BOOL");
    props.globals.initNode("systems/electrical/serviceable",0,"BOOL");
    props.globals.initNode("controls/electric/external-power",0,"BOOL");
    setprop("controls/lighting/efis-norm",0.8);
    setprop("controls/lighting/panel-norm",0.0);
    setprop("controls/lighting/instruments-norm",0.0);
    setprop("controls/lighting/instrument-lights-norm",0.5);

    append(lights_input,props.globals.initNode("controls/lighting/landing-light[0]",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/landing-light[0]",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/landing-light[1]",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/landing-light[1]",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/nav-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/nav-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/cabin-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/cabin-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/map-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/map-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/wing-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/wing-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/recog-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/recog-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/logo-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/logo-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/taxi-light",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/taxi-light",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/beacon-state/state",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/beacon",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/strobe-state/state",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/strobe",0,"DOUBLE"));
    append(lights_load,1);

    append(rbus_input,props.globals.initNode("controls/electric/wiper-switch",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/wiper",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,props.globals.initNode("controls/engines/engine[0]/fuel-pump",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/fuel-pump[0]",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,props.globals.initNode("controls/engines/engine[1]/fuel-pump",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/fuel-pump[1]",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,props.globals.initNode("controls/engines/engine[1]/starter",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/starter[1]",0,"DOUBLE"));
    append(rbus_load,1);

    append(lbus_input,props.globals.initNode("controls/engines/engine[0]/starter",0,"BOOL"));
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/starter",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,props.globals.initNode("instrumentation/turn-coordinator/serviceable",1,"BOOL"));
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/turn-coordinator",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,props.globals.initNode("instrumentation/DG/serviceable",1,"BOOL"));
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/DG",0,"DOUBLE"));
    append(lbus_load,1);

    append(avbus_input,props.globals.initNode("instrumentation/adf/func-knob",1,"INT"));
    append(avbus_output,props.globals.initNode("systems/electrical/outputs/adf",0,"DOUBLE"));
    append(avbus_load,1);
    append(avbus_input,props.globals.initNode("instrumentation/dme/switch-position[1]",0,"INT"));
    append(avbus_output,props.globals.initNode("systems/electrical/outputs/dme",0,"DOUBLE"));
    append(avbus_load,1);
    append(avbus_input,props.globals.initNode("instrumentation/kt-70/inputs/serviceable",1,"BOOL"));
    append(avbus_output,props.globals.initNode("systems/electrical/outputs/transponder",0,"DOUBLE"));
    append(avbus_load,1);
    append(avbus_input,props.globals.initNode("instrumentation/comm/serviceable",1,"BOOL"));
    append(avbus_output,props.globals.initNode("systems/electrical/outputs/comm",0,"DOUBLE"));
    append(avbus_load,1);
    append(avbus_input,props.globals.initNode("instrumentation/comm[1]/serviceable",1,"BOOL"));
    append(avbus_output,props.globals.initNode("systems/electrical/outputs/comm[1]",0,"DOUBLE"));
    append(avbus_load,1);
    append(avbus_input,props.globals.initNode("instrumentation/nav/serviceable",1,"BOOL"));
    append(avbus_output,props.globals.initNode("systems/electrical/outputs/nav",0,"DOUBLE"));
    append(avbus_load,1);
    append(avbus_input,props.globals.initNode("instrumentation/nav[1]/serviceable",1,"BOOL"));
    append(avbus_output,props.globals.initNode("systems/electrical/outputs/nav[1]",0,"DOUBLE"));
    append(avbus_load,1);
}


update_virtual_bus = func( dt ) {
    var PWR = getprop("systems/electrical/serviceable");
    var AV = getprop("controls/electric/avionics-switch");

    var xtie=0;
    var left_load = 0.0;
    var right_load = 0.0;

    var battery_volts = battery.get_output_volts();
    var alternator1_volts = alternator1.get_output_volts();
    var alternator2_volts = alternator2.get_output_volts();

    # Feed the two DC buses either from alternator or from battery.
    if (alternator1_volts > battery_volts) {
       lbus_volts = alternator1_volts;
    }
    else { lbus_volts = battery_volts; }
    if (alternator2_volts > battery_volts) {
       rbus_volts = alternator2_volts;
    }
    else { rbus_volts = battery_volts; }

    # If the electrical system is not serviceable, cut power.
    lbus_volts *=PWR;
    rbus_volts *=PWR;

    Lbus.setValue(lbus_volts);
    left_load = lh_bus(lbus_volts);
    Rbus.setValue(rbus_volts);
    right_load = rh_bus(rbus_volts);

    # Feed the AC bus with the bus selected by the inverter switch iff the avionics switch is ON
    var avbus = 0;
    if(inverter_switch.getValue ()) {
        avbus = AV*lbus_volts;
        left_load += av_bus (avbus);
        ACbus.setValue (avbus*4.1);
    }
    else {
        avbus = AV*rbus_volts;
        right_load += av_bus (avbus);
        ACbus.setValue (avbus*4.1);
    }

    # Apply load to alternators that are on
    if (lbus_volts > battery_volts) {
        alternator1.apply_load(left_load);
    }
    if (rbus_volts > battery_volts) {
        alternator2.apply_load(right_load);
    }

    # If we've lost power on the left bus that powers them, the speedbrakes fail into the closed position.
    if (lbus_volts < 5) {
        setprop ("controls/flight/speedbrake", 0);
    }

    if(rbus_volts > 5 and lbus_volts>5) xtie=1;
    XTie.setValue(xtie);
    if(rbus_volts > 5 or  lbus_volts>5) right_load += lighting(24);
    ammeter = 0.0;

    return left_load + right_load;
}

rh_bus = func(bv) {
    var load = 0.0;
    var srvc = 0.0;
    for(var i=0; i<size(rbus_input); i+=1) {
        var srvc = rbus_input[i].getValue();
        load += rbus_load[i] * srvc;
        rbus_output[i].setValue(bv * srvc);
    }
    return load;
}

lh_bus = func(bv) {
    var load = 0.0;
    var srvc = 0.0;
    for(var i=0; i<size(lbus_input); i+=1) {
        var srvc = lbus_input[i].getValue();
        load += lbus_load[i] * srvc;
        lbus_output[i].setValue(bv * srvc);
    }

    setprop("systems/electrical/outputs/flaps",bv);
    return load;
}

av_bus = func(bv) {
    var load = 0.0;
    var srvc = 0.0;

    for(var i=0; i<size(avbus_input); i+=1) {
        var srvc = avbus_input[i].getValue();
        load += avbus_load[i] * srvc;
        avbus_output[i].setValue(bv * srvc);
    }
    return load;
}

lighting = func(bv) {
    var load = 0.0;
    var srvc = 0.0;

    for(var i=0; i<size(lights_input); i+=1) {
        var srvc = lights_input[i].getValue();
        load += lights_load[i] * srvc;
        lights_output[i].setValue(bv * srvc);
    }

#setprop("sim/multiplay/generic/int",getprop("systems/electrical/outputs/strobe"));
#setprop("sim/multiplay/generic/int[1]",getprop("systems/electrical/outputs/beacon"));
#setprop("sim/multiplay/generic/int[2]",getprop("systems/electrical/outputs/taxi-light"));
#setprop("sim/multiplay/generic/int[3]",getprop("systems/electrical/outputs/landing-light[0]"));
#setprop("sim/multiplay/generic/int[3]",getprop("systems/electrical/outputs/landing-light[1]"));
#setprop("sim/multiplay/generic/int[4]",getprop("systems/electrical/outputs/recog-lights"));

return load;

}

update_electrical = func {
    var scnd = getprop("sim/time/delta-sec");
    update_virtual_bus( scnd );
settimer(update_electrical, 0);
}
