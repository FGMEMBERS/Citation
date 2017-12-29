
var citation_save_general = [
  "/controls/save-state/general",
  "/controls/save-state/fuel",
  "/controls/save-state/radios",
  "/controls/save-state/models",
  "/controls/save-state/circuitBreakers",
  "/engines/engine[0]/running-time-s",
  "/engines/engine[1]/running-time-s",
  "/sim/aircraft-class",
  "/sim/aircraft-operator",
  "/sim/dimensions/parkpos-offset-m",
  "/sim/dimensions/radius-m",
  "/sim/model/livery",
];

var citation_array_fuel = [
  "/consumables/fuel/fuel-gal_us-0",
  "/consumables/fuel/fuel-gal_us-1",
  "/sim/weight[0]/weight-lb",
  "/sim/weight[1]/weight-lb",
  "/sim/weight[2]/weight-lb",
  "/sim/weight[3]/weight-lb",
];

var citation_array_models = [
  "/controls/human-models",
  "/sim/yokes-visible",
  "/controls/seat/armrests-pos",
];

var citation_array_radios = [
  "/instrumentation/comm/frequencies/selected-mhz",
  "/instrumentation/comm/frequencies/standby-mhz",
  "/instrumentation/comm/volume-def",
  "/instrumentation/comm[1]/frequencies/selected-mhz",
  "/instrumentation/comm[1]/frequencies/standby-mhz",
  "/instrumentation/comm[1]/volume-def",
  "/instrumentation/nav/frequencies/selected-mhz",
  "/instrumentation/nav/frequencies/standby-mhz",
  "/instrumentation/nav/volume",
  "/instrumentation/nav[1]/frequencies/selected-mhz",
  "/instrumentation/nav[1]/frequencies/standby-mhz",
  "/instrumentation/nav[1]/volume",
  "/instrumentation/adf/frequencies/selected-khz",
  "/instrumentation/adf/frequencies/standby-khz",
  "/instrumentation/adf/volume-norm",
  "/instrumentation/adf[1]/frequencies/selected-khz",
  "/instrumentation/adf[1]/frequencies/standby-khz",
  "/instrumentation/adf[1]/volume-norm",
  "/instrumentation/transponder/id-code",
  "/instrumentation/transponder/inputs/knob-mode",
  "/instrumentation/airspeed-indicator/index-marker",
  "/instrumentation/clock/m877/mode-string",
  "/instrumentation/dme/switch-position",
  "/instrumentation/dme/switch-position[1]",
];

var citation_array_circuitBreakers = [

# hot battery bus / located in J-Box #

  "/controls/electric/circuit-breakers/bus-battery-hot/cb-light-comp",
  "/controls/electric/circuit-breakers/bus-battery-hot/cb-light-enginst",
  "/controls/electric/circuit-breakers/bus-battery-hot/cb-ignition",
  "/controls/electric/circuit-breakers/bus-battery-hot/cb-emer-power",

# emergency bus / on right CB panel #

  "/controls/electric/circuit-breakers/bus-emer/cb-dc-nav2",
  "/controls/electric/circuit-breakers/bus-emer/cb-dc-comm1",
  "/controls/electric/circuit-breakers/bus-emer/cb-dc-dg2",
  "/controls/electric/circuit-breakers/bus-emer/cb-light-flood",

# battery bus / located in J-Box #

  "/controls/electric/circuit-breakers/bus-battery/cb-batt-voltage",

# left isolated bus / located in J-Box  #

  "/controls/electric/circuit-breakers/bus-left-iso/cb-gen-ammeter-left",
  "/controls/electric/circuit-breakers/bus-left-iso/cb-gen-sense-left",
  "/controls/electric/circuit-breakers/bus-left-iso/cb-light-start-left",
  "/controls/electric/circuit-breakers/bus-left-iso/cb-gen-voltage-left",

# right isolated bus / located in J-Box  #

  "/controls/electric/circuit-breakers/bus-right-iso/cb-gen-ammeter-right",
  "/controls/electric/circuit-breakers/bus-right-iso/cb-gen-sense-right",
  "/controls/electric/circuit-breakers/bus-right-iso/cb-light-start-right",
  "/controls/electric/circuit-breakers/bus-right-iso/cb-gen-voltage-right",

# left main bus / located on left CB panel #

  "/controls/electric/circuit-breakers/cb-bus-left-1",
  "/controls/electric/circuit-breakers/cb-bus-left-2",
  "/controls/electric/circuit-breakers/cb-bus-left-3",

  "/controls/electric/circuit-breakers/bus-left/cb-bus-left-starter",
  "/controls/electric/circuit-breakers/bus-left/cb-bus-left-inverter",
  "/controls/electric/circuit-breakers/bus-left/cb-bus-left-x-over",

  "/controls/electric/circuit-breakers/bus-left/cb-engine-fan-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-itt-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-turbine-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-fuelflow-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-qty-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-oilt-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-oilp-left",

  "/controls/electric/circuit-breakers/bus-left/cb-engine-ign-right",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-boost-right",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-shutoff-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-fire-left",

  "/controls/electric/circuit-breakers/bus-left/cb-sys-skid-ctrl",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-thrustrev-left",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-flap-motor",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-flap-ctrl",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-aoa",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-gear-ctrl",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-engine-sync",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-pitch-trim",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-nose-wheel-rpm",
  "/controls/electric/circuit-breakers/bus-left/cb-sys-speed-brake",

  "/controls/electric/circuit-breakers/bus-left/cb-anti-ice-pitot-left",
  "/controls/electric/circuit-breakers/bus-left/cb-anti-ice-aoa",
  "/controls/electric/circuit-breakers/bus-left/cb-anti-ice-engine-left",
  "/controls/electric/circuit-breakers/bus-left/cb-anti-ice-bleedair-ws-temp",
  "/controls/electric/circuit-breakers/bus-left/cb-anti-ice-bleedair-ws",

  "/controls/electric/circuit-breakers/bus-left/cb-inst-gyro-standby",
  "/controls/electric/circuit-breakers/bus-left/cb-inst-oat",
  "/controls/electric/circuit-breakers/bus-left/cb-inst-clock-left",

  "/controls/electric/circuit-breakers/bus-left/cb-env-normalp",
  "/controls/electric/circuit-breakers/bus-left/cb-env-fan",
  "/controls/electric/circuit-breakers/bus-left/cb-env-temp",

  "/controls/electric/circuit-breakers/bus-left/cb-warn-batt",
  "/controls/electric/circuit-breakers/bus-left/cb-warn-gear",
  "/controls/electric/circuit-breakers/bus-left/cb-warn-lts1",

  "/controls/electric/circuit-breakers/bus-left/cb-light-panel-left",
  "/controls/electric/circuit-breakers/bus-left/cb-light-panel-el",
  "/controls/electric/circuit-breakers/bus-left/cb-light-beacon",
  "/controls/electric/circuit-breakers/bus-left/cb-light-strobe",
  "/controls/electric/circuit-breakers/bus-left/cb-light-winginsp",
  "/controls/electric/circuit-breakers/bus-left/cb-light-nav",

  "/controls/electric/circuit-breakers/bus-left/cb-rec-flight",
  "/controls/electric/circuit-breakers/bus-left/cb-rec-voice",

# CROSS OVER / left main bus / located on right CB panel #

  "/controls/electric/circuit-breakers/bus-left/cb-dc-comm2",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-nav1",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-dme1",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-xpdr1",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-adf1",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-audio1",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-phone",

  "/controls/electric/circuit-breakers/bus-left/cb-dc-ap",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-efis-disp",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-efis-efis",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-efis-adi",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-efis-hsi",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-voice-adv",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-radalt",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-fd1",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-rmi1",
  "/controls/electric/circuit-breakers/bus-left/cb-dc-dg1",

# left main bus / located in J-Box #

  "/controls/electric/circuit-breakers/bus-left/cb-bus-sense-left",
  "/controls/electric/circuit-breakers/bus-left/cb-engine-boost-left",
  "/controls/electric/circuit-breakers/bus-left/cb-annun-genoff-left",
  "/controls/electric/circuit-breakers/bus-left/cb-light-landing-left",
  "/controls/electric/circuit-breakers/bus-left/cb-light-recog-left",
  "/controls/electric/circuit-breakers/bus-left/cb-light-advisory",
  "/controls/electric/circuit-breakers/bus-left/cb-light-indirect",
  "/controls/electric/circuit-breakers/bus-left/cb-entertainment",

# right main bus / located on right CB panel #

  "/controls/electric/circuit-breakers/cb-bus-right-1",
  "/controls/electric/circuit-breakers/cb-bus-right-2",
  "/controls/electric/circuit-breakers/cb-bus-right-3",

  "/controls/electric/circuit-breakers/bus-right/cb-bus-right-starter",
  "/controls/electric/circuit-breakers/bus-right/cb-bus-right-inverter",
  "/controls/electric/circuit-breakers/bus-right/cb-bus-right-x-over",

  "/controls/electric/circuit-breakers/bus-right/cb-engine-fan-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-itt-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-turbine-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-fuelflow-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-qty-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-oilt-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-oilp-right",

  "/controls/electric/circuit-breakers/bus-right/cb-dc-dme2",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-xpdr2",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-adf2",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-audio2",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-warn",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-comm3",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-nav-area",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-gpws",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-tas-htr",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-nav-vlf",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-nav-db",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-fms",

  "/controls/electric/circuit-breakers/bus-right/cb-dc-radar",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-fd2",
  "/controls/electric/circuit-breakers/bus-right/cb-dc-rmi2",

# CROSS OVER / right main bus / located on left CB panel #

  "/controls/electric/circuit-breakers/bus-right/cb-engine-ign-left",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-boost-left",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-shutoff-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-fire-right",

  "/controls/electric/circuit-breakers/bus-right/cb-env-emerp",

  "/controls/electric/circuit-breakers/bus-right/cb-inst-ralt",
  "/controls/electric/circuit-breakers/bus-right/cb-inst-flt-hr",
  "/controls/electric/circuit-breakers/bus-right/cb-inst-clock-right",

  "/controls/electric/circuit-breakers/bus-right/cb-anti-ice-pitot-right",
  "/controls/electric/circuit-breakers/bus-right/cb-anti-ice-engine-right",
  "/controls/electric/circuit-breakers/bus-right/cb-anti-ice-surface",
  "/controls/electric/circuit-breakers/bus-right/cb-anti-ice-alcohol",

  "/controls/electric/circuit-breakers/bus-right/cb-warn-lts2",
  "/controls/electric/circuit-breakers/bus-right/cb-warn-speed",

  "/controls/electric/circuit-breakers/bus-right/cb-sys-equip-cool",
  "/controls/electric/circuit-breakers/bus-right/cb-sys-thrustrev-right",

  "/controls/electric/circuit-breakers/bus-right/cb-light-panel-center",
  "/controls/electric/circuit-breakers/bus-right/cb-light-panel-right",

  "/controls/electric/circuit-breakers/bus-right/cb-ac-ap",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-fd1",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-air-data",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-vgyro1",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-radar",

  "/controls/electric/circuit-breakers/bus-right/cb-ac-fd2",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-vgyro2",

  "/controls/electric/circuit-breakers/bus-right/cb-ac-nav1",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-rmi-adf1",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-hsi1",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-adi1",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-gpws",

  "/controls/electric/circuit-breakers/bus-right/cb-ac-nav2",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-rmi-adf2",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-hsi2",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-adi2",
  "/controls/electric/circuit-breakers/bus-right/cb-ac-efis",

# right main bus / located in J-Box #

  "/controls/electric/circuit-breakers/bus-right/cb-bus-sense-right",
  "/controls/electric/circuit-breakers/bus-right/cb-engine-boost-right",
  "/controls/electric/circuit-breakers/bus-right/cb-annun-genoff-right",
  "/controls/electric/circuit-breakers/bus-right/cb-light-landing-right",
  "/controls/electric/circuit-breakers/bus-right/cb-light-recog-right",
  "/controls/electric/circuit-breakers/bus-right/cb-light-cabin",
  "/controls/electric/circuit-breakers/bus-right/cb-light-toilet",

];

var reset_circuitBreakers = func() {
  screen.log.write("All circuit-breakers reset to closed.");
  foreach(var path; citation_array_circuitBreakers) {
    setprop(path, 1);
  }
}


var switchProp = func(which) {
  if (getprop("/controls/save-state/" ~ which)) {
    setprop("/controls/save-state/" ~ which, 0);
  }
  else {
    setprop("/controls/save-state/" ~ which, 1);
  }
  saveState.update_saveState();
}


var update_saveState = func() {

  aircraft.data.catalog = [];

  aircraft.data.add(citation_save_general);

  if (getprop("/controls/save-state/general")) {
    if (getprop("/controls/save-state/fuel")) {
      aircraft.data.add(citation_array_fuel);
    }

    if (getprop("/controls/save-state/models")) {
      aircraft.data.add(citation_array_models);
    }

    if (getprop("/controls/save-state/radios")) {
      aircraft.data.add(citation_array_radios);
    }

    if (getprop("/controls/save-state/circuitBreakers")) {
      aircraft.data.add(citation_array_circuitBreakers);
    }
#    aircraft.data.save();
  }
}
