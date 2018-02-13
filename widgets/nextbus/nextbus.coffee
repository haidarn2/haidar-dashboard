class Dashing.Nextbus extends Dashing.Widget

  #container = ;
  
  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
  	###
    predictions = data['predictions']

    container = $(@node).find('#predictions');
    container.empty();

    for direction in Object.keys(predictions)
    	route = predictions[direction]
    	if Object.keys(route).length > 0
    		@addPrediction(route, container);
	###

  addPrediction: (route, container) ->
    for entry in route.times
    	container.append('<h1>' + @padLeft(entry.min, 2) + ':' + @padLeft(entry.sec, 2) + '</h1>');

  padLeft: (val, len, padChar = '0') ->
    val += '';
    numPads = len - val.length;
    if (numPads > 0) then new Array(numPads + 1).join(padChar) + val else val