reduce = function(key, values) {
  var total = 0;
  return { values: values }
  for(var i=0; i<values.length; i++) {
    total += values[i].count;
  }
  return { count : total };
}