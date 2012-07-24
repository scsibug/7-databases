function (v) {
    var totals = {};
    for (var i in v) {
        for (var style in v[i]) {
            if (totals[style]) totals[style] += v[i][style];
            else               totals[style] = v[i][style];
        }
    }
    return [totals];
}