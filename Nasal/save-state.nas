
var citation_save_general = [
  "/controls/save-state/general",
  "/controls/save-state/fuel",
  "/controls/save-state/radios",
  "/controls/save-state/models",
  "/controls/save-state/circuitBreakers",
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
  "/controls/electric/circuit-breakers/bus-battery-hot/cb-clock-left",
  "/controls/electric/circuit-breakers/bus-battery-hot/cb-clock-right",
  "/controls/electric/circuit-breakers/bus-emer/cb-light-emer",
  "/controls/electric/circuit-breakers/bus-emer/cb-light-panel-el",
  "/controls/electric/circuit-breakers/bus-emer/cb-light-panel-enginstr",
  "/controls/electric/circuit-breakers/bus-emer/cb-light-panel-flood",
  "/controls/electric/circuit-breakers/bus-emer[1]",
  "/controls/electric/circuit-breakers/bus-left/cb-flap-ctl",
  "/controls/electric/circuit-breakers/bus-left/cb-flap-motor",
  "/controls/electric/circuit-breakers/bus-left/cb-gear-ctl",
  "/controls/electric/circuit-breakers/bus-left/cb-light-beacon",
  "/controls/electric/circuit-breakers/bus-left/cb-light-cabin-ind",
  "/controls/electric/circuit-breakers/bus-left/cb-light-landing-left",
  "/controls/electric/circuit-breakers/bus-left/cb-light-panel-center",
  "/controls/electric/circuit-breakers/bus-left/cb-light-panel-left",
  "/controls/electric/circuit-breakers/bus-left/cb-light-panel-right",
  "/controls/electric/circuit-breakers/bus-left/cb-light-recog-left",
  "/controls/electric/circuit-breakers/bus-left/cb-light-strobe",
  "/controls/electric/circuit-breakers/bus-left/cb-light-winginsp",
  "/controls/electric/circuit-breakers/bus-left/cb-light-nav",
  "/controls/electric/circuit-breakers/bus-left/cb-pitch-trim",
  "/controls/electric/circuit-breakers/bus-left/cb-speedbrakes",
  "/controls/electric/circuit-breakers/bus-left/cb-start-left",
  "/controls/electric/circuit-breakers/bus-left/cb-thrust-reverser-left",
  "/controls/electric/circuit-breakers/bus-left/cb-thrust-reverser-right",
  "/controls/electric/circuit-breakers/bus-left-1",
  "/controls/electric/circuit-breakers/bus-left-2",
  "/controls/electric/circuit-breakers/bus-left-3",
  "/controls/electric/circuit-breakers/bus-right/cb-ground-prox",
  "/controls/electric/circuit-breakers/bus-right/cb-light-cabin-read",
  "/controls/electric/circuit-breakers/bus-right/cb-light-landing-right",
  "/controls/electric/circuit-breakers/bus-right/cb-light-recog-right",
  "/controls/electric/circuit-breakers/bus-right/cb-start-right",
  "/controls/electric/circuit-breakers/bus-right-1",
  "/controls/electric/circuit-breakers/bus-right-2",
  "/controls/electric/circuit-breakers/bus-right-3",
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
