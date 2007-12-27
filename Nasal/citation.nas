var view_list =[];
var Sview = props.globals.getNode("/sim").getChildren("view");
foreach (v;Sview) {
append(view_list,"sim/view["~v.getIndex()~"]/config/default-field-of-view-deg");
}
aircraft.data.add(view_list);
