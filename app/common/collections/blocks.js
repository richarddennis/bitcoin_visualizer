(function() {
  var Blocks, Moment, config, pageLimit, pollInterval, _;

  config = require('config');

  _ = require('lodash');

  Moment = require('moment');

  pageLimit = 10;

  pollInterval = 1000 * 20;

  Blocks = function() {
    console.log('block collection instantiated, fetching initial data');
    this.curPage = 1;
    this.pageSize = 200;
    return this.getHistorical(null, this.pollForLatest.bind(this));
  };

  Blocks.prototype = new Array();

  Blocks.prototype.parse = function(one) {
    var m;
    m = new Moment(one.block_time);
    one.date = m.format('YYYY-MM-DD');
    return one;
  };

  Blocks.prototype.getLatest = function() {
    var request;
    request = new XMLHttpRequest();
    request.open('GET', "" + config.api + "/v1/btc/block/latest?api_key=" + config.blocktrailKey, true);
    request.onerror = this.gotErr.bind(this);
    request.onload = (function() {
      if (request.status >= 200 && request.status < 400) {
        return this.gotLatest.call(this, JSON.parse(request.responseText));
      } else {
        return gotErr(request);
      }
    }).bind(this);
    return request.send();
  };

  Blocks.prototype.gotLatest = function(resp) {
    var wasInserted;
    console.log('gotLatest', resp.hash);
    wasInserted = this.safeInsert(this.parse(resp));
    if (wasInserted) {
      return this.onChangeCall();
    }
  };

  Blocks.prototype.getHistorical = function(page, callback) {
    var request;
    page = page || this.curPage;
    request = new XMLHttpRequest();
    request.open('GET', "" + config.api + "/v1/btc/all-blocks?page=" + page + "&limit=" + this.pageSize + "&sort_dir=desc&api_key=" + config.blocktrailKey, true);
    request.onerror = this.gotErr.bind(this);
    request.onload = (function() {
      var resp;
      if (request.status >= 200 && request.status < 400) {
        resp = JSON.parse(request.responseText);
        this.gotHistorical.call(this, resp);
        if (typeof callback === 'function') {
          return callback.call(this, resp);
        }
      } else {
        return gotErr(request);
      }
    }).bind(this);
    return request.send();
  };

  Blocks.prototype.gotHistorical = function(resp) {
    var one, _i, _len, _ref;
    _ref = resp.data;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      one = _ref[_i];
      this.push(this.parse(one));
    }
    this.onChangeCall();
    this.curPage++;
    if (this.curPage > pageLimit) {
      return;
    }
    return this.getHistorical();
  };

  Blocks.prototype.gotErr = function(req) {
    return console.warn('error response from server on collection/blocks', req);
  };

  Blocks.prototype.conErr = function() {
    return console.warn('error setting up xhr request on collection/blocks', arguments);
  };

  Blocks.prototype.safeInsert = function(block) {
    if (this[0] && this[0].hash === block.hash) {

    } else if (_.find(this, {
      hash: block.hash
    })) {
      return console.warn("asked to re-insert a block that isn't at the front, but is already in the data set");
    } else {
      console.info("blocks.safeInsert() Adding a new block to the front of the chain");
      return this.unshift(block);
    }
  };

  Blocks.prototype.pollForLatest = function() {
    console.log('pollForLatest');
    this.getLatest();
    return setInterval(this.getLatest.bind(this), pollInterval);
  };

  Blocks.prototype.onChange = function(fn) {
    this._handlers = this._handlers || {};
    this._handlers.onChange = this._handlers.onChange || [];
    return this._handlers.onChange.push(fn);
  };

  Blocks.prototype.onChangeCall = function() {
    if (!(this._handlers && this._handlers.onChange)) {
      return;
    }
    return this._handlers.onChange.forEach(function(fn) {
      return fn.apply(this, arguments);
    });
  };

  module.exports = Blocks;

}).call(this);
