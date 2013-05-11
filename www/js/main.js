(function() {
  var gameReset, introReset;

  this.sensList = ['low', 'default', 'high', 'very high', 'extreme'];

  this.sensValue = [1, 1.3, 1.6, 2, 4];

  gameReset = function() {
    var obj, _i, _len, _ref;

    this.health = 100;
    this.speed = 0;
    this.score = 0;
    this.status = 1;
    this.shipX = 0;
    this.shipY = 0;
    this.view = 1;
    this.maxSpeed = 52;
    this.speedLimit = 100;
    this.zCamera2 = 0;
    _ref = this.objs;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      obj = _ref[_i];
      obj.position.x = Math.random() * 5000 - 2500;
      obj.position.y = -300;
    }
    return $('#score').html(score);
  };

  introReset = function(gameCompleted) {
    var hiScore;

    this.speed = 0;
    this.view = 2;
    this.status = 0;
    hiScore = localStorage.getItem('fk2hiscore');
    if (hiScore == null) {
      hiScore = 0;
    }
    $('#score').html("Hi-Score: " + hiScore);
    $('#hud').hide();
    return $('#like').show();
  };

}).call(this);
