function (v) {
    var parsed_data = JSON.parse(v.values[0].data);
    var data {};
    data[parsed_data.style] = parsed_data.capacity;
    return [data];
}