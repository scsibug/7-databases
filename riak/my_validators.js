function good_score(object) {
    try {
        var data = JSON.parse( object.values[0].data );
        if (!data.score || data.score === '') {
            throw('Score is required');
        }
        if (data.score < 1 || data.score > 4) {
            throw('Score must be from 1 to 4');
        }
    } catch( message ) {
        return { "fail" : message };
    }
    return object;
}