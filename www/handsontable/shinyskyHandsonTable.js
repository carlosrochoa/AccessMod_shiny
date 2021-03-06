window.tables = {};

/* handson table from shiny sky*/

//input binding
var hotable = new Shiny.InputBinding();

$.extend(hotable, {
  find: function(scope) {
    return $(scope).find(".hotable");
  },
  getValue: function(el) {
    var ht = window.tables[el.id];
    //var ht = $(el).handsontable("getInstance");

    if( ht === undefined){
      return (null);
    } else {

      var data = ht.getData();
      var res = {};
      var cols = ht.getColHeader();

      for(var c= 0; c<cols.length; c++){
        var col = cols[c];
        res[col] = [];
        for(var l=0;l<data.length;l++){
          res[col].push(data[l][c]);
        }
      }

      return ({
        colHeaders: cols,
        data: JSON.stringify(res)
      });
    }
  },
  setValue: function(el, value) { },
  subscribe: function(el, callback) {
    $(el).on("afterChange", function(e) {
      callback();
    });
  },
  unsubscribe: function(el) {
    $(el).off(".hotable");
  }
});

Shiny.inputBindings.register(hotable);

//output binding
var hotableOutput = new Shiny.OutputBinding();
$.extend(hotableOutput, {
  find: function(scope) {
    return $(scope).find('.hotable');
  },
  renderValue: function(el, json) {
    if (json === null) return;
    if (!json.hasOwnProperty("data")) return;

    var data = json.data;

     var settings = {
      columns: json.columns,
      manualColumnResize: true,
      minSpareRows: json.nSpareRow, // at least one empty row
      maxRows : json.maxRows, // if no thing is given, set as the nrows(df)
      colHeaders: json.colHeaders,
      handlebar: false,
      stretchH:json.stretched,
      columnSorting: true,
      data:data
    }; 

    if(window.tables[el.id]){
      var ht = window.tables[el.id];
      ht.updateSettings(settings);
    }else{
      
      window.tables[el.id] = new Handsontable(el,settings);
    }

    if(json.idToolsFilter){
      hotableMakeFilterBox(el.id,"#"+json.idToolsFilter);
    }

    window.tables[el.id].addHook("afterChange", function() {
      $(el).trigger("afterChange");
    });
    window.tables[el.id].addHook("beforeColumnSort",function(id,order){
      if(typeof order !== "undefined"){
        var colType = this.getDataType(0, id, 100, id);
        if(colType === "checkbox"){
          alert("Sorry, sorting boolean columns does not work. See : https://github.com/handsontable/handsontable/issues/4047");  
        }
      }
    
    });

    $(el).trigger("afterChange");
  }
});
Shiny.outputBindings.register(hotableOutput, "hotable");








/**
* Create ui for a conditional update select componant
* @param {String} id Id of the table stored in window.tables
* @param {String} selectorContainer Optional selector to get the element to populate the component with
*/
function hotableMakeFilterBox(id,selectorContainer) {
  var elCol, colOpt, colType, colId, colData;
  var elNumericInput, elSelectValues;
  var elProgress = elCreate("span");
  var opsNum = ["==", ">=", "<=", ">", "<", "!="];
  var opsString = ["==", "!="];
  var hot = window.tables[id];
  var elTable = document.getElementById(id);
  var elSelectContainer = document.querySelector(selectorContainer) || elCreate("div");
  while(elSelectContainer.firstElementChild){
    elSelectContainer.firstElementChild.remove();
  }

  var options = {
    valueSet : true,
    valueUnset: false,
    col : "amSelect"
  };

  if(elSelectContainer.dataset.opt){
    options = JSON.parse(elSelectContainer.dataset.opt);

  }
  elSelectContainer.classList.add("handsonFiltersContainer");
  var elSelectOpts = elCreate("div");
  var elBtnAdd = elCreate("a");
  var elBtnRemove = elCreate("a");
  elBtnAdd.innerText = "[ " + ( options.labelSet || "set" ) + " ]" ;
  elBtnRemove.innerText = "[ " + ( options.labelUnset || "unselect" ) + " ]";

  var columns = getHeaderObj(hot);
  var elSelectColHeader = selectCreate(columns);
  var elSelectOpsNum = selectCreate(opsNum);
  var elSelectOpsString = selectCreate(opsString);

  elSelectContainer.appendChild(elSelectColHeader);
  elSelectContainer.appendChild(elSelectOpts);
  elSelectContainer.appendChild(elBtnAdd);
  elSelectContainer.appendChild(elBtnRemove);
  elSelectContainer.appendChild(elProgress);

  var updateSelect = function() {
    while (elSelectOpts.firstChild) {
      elSelectOpts.removeChild(elSelectOpts.firstChild);
    }
    elCol = elSelectColHeader;
    colOpt = elCol.options[elCol.selectedIndex].dataset.opt;
    colId = JSON.parse(colOpt).value;
    if (colId) {
      colData = hot.getDataAtCol(colId);
      colType = hot.getDataType(0, colId, 100, colId);
      if (colType == "numeric") {
        colData.forEach(function(d){if(d===null){d=0;}});
        elSelectOpts.appendChild(elSelectOpsNum);
        elNumericInput = elCreate("input");
        elNumericInput.type = "number";
        elSelectOpts.appendChild(elNumericInput);
      } else {
        colData.forEach(function(d){if(d===null){d="";}});
        elSelectOpts.appendChild(elSelectOpsString);
        elSelectValues = selectCreate(colData);
        elSelectOpts.appendChild(elSelectValues);
      }
    }
  };

  var applySelection = function(cmd) {

    var set = cmd === "set" ? options.valueSet : options.valueUnset;

    var isNum = colType === "numeric";
    var col = elSelectColHeader.value;
    var op = isNum ?
      elSelectOpsNum.value :
      elSelectOpsString.value;

    var val = isNum ?
      elNumericInput.value :
      elSelectValues.value;

    hotableSetColValuesByCond(id, {
      col: options.col,
      set: set,
      whereCol: col,
      whereVal: val,
      whereOp: op,
      elProgress : elProgress
    });
  };

  var cmdSet = function(){return applySelection("set");};
  var cmdUnset = function(){return applySelection("unset");};

  elSelectColHeader.addEventListener("change", updateSelect);
  elBtnAdd.addEventListener("click", cmdSet);
  elBtnRemove.addEventListener("click", cmdUnset);
  if(!selectorContainer){
    elTable.parentNode.insertBefore(elSelectContainer, elTable);
  }
  updateSelect();

}




/**
* Update a column of an handsontable using a given value
* @param {String} id Id of the table stored in window.tables
* @param {Object} options 
* @param {String} options.col Column to update
* @param {*} options.set Value to update the column with 
*/
function  hotableSetColValues(id,options){
  var o = options || {};
  var res   = [];
  var ht = window.tables[id];
  if(!ht) return;

  rc = ht.countRows();
  cc = ht.countCols();
  if(rc > 0 && cc > 0){
    // search 
    hed = ht.getColHeader();
    pos = hed.indexOf(o.col);
    if( pos !== undefined){
      for(i = 0; i < rc; i++){
        res.push([i,pos,o.set]);
      }
      ht.setDataAtCell(res);
    }
  }
}


/**
* Create a new worker from a function
* @param {Function} fun function to execute in the worker
*/
function newWorker(fun) {
  // convert input function to string
  fun = fun.toString();
  fun = fun
    .substring(
      fun.indexOf("{") + 1,
      fun.lastIndexOf("}")
    );
  // Make a blob
  var blob = new Blob(
    [fun], {
      type: "application/javascript"
    }
  );
  // convert as url for new worker
  var blobUrl = URL.createObjectURL(blob);

  // return new worker
  return (new Worker(blobUrl));
}


/*
* Worker for the conditional search
*/
function workerSetColCond() {
  // Inital message
  postMessage({
    progress: 0,
    message: "start"
  });


  // handle message send from the main thread
  onmessage = function(e) {
    var data = e.data;
    var res = [],
      a1 = data.targetArray,
      a2 = data.filterArray,
      set = data.setValue,
      v2 = data.filterValue,
      c1 = data.targetCol,
      c2 = data.filterCol,
      nRow = a1.length,
      op = data.operator || "==";

    var fun = {
      "==": function(a, b) {
        return a == b;
      },
      ">=": function(a, b) {
        return a >= b;
      },
      "<=": function(a, b) {
        return a <= b;
      },
      ">": function(a, b) {
        return a > b;
      },
      "<": function(a, b) {
        return a < b;
      },
      "!=": function(a, b) {
        return a != b;
      },
      "": function(a, b) {
        return a == b;
      }
    };

    for (var i = 0; i < nRow; i++) {
      progress = ((i + 1) / nRow) * 100;
      if (progress === 0 || progress == 100 || i % 1000 === 0) {
        postMessage({
          progress: progress,
          message: (i + 1) + "/" + nRow
        });
      }

      if (fun[op](a2[i], v2)) {
        res.push([i, c1, set]);
      } else {
        res.push([i, c1, a1[i]]);
      }
    }
    postMessage({
      result: res
    });
    close();
  };

}

Shiny.addCustomMessageHandler('hotableSetColValuesByCond',hotableSetColValuesByCondWrapper);

function hotableSetColValuesByCondWrapper(o){
   hotableSetColValuesByCond(o.id,o);
}

/**
* Set value of a column based on a test on another column
* @param {String} id Id of a table stored in window.tables
* @param {Object} options 
* @param {String} options.col Name or index of column to alter
* @param {String} options.colWhere Name or index of column to query
* @param {*} options.set Value to update the column with
* @param {String} options.whereOp Operator to use in the compare function. 
* @param {Element} options.elProgress Element to update with the progress percentage
*/
function hotableSetColValuesByCond(id, options) {
  var o = options || {};
  var ht = window.tables[id];

  if (!ht)return;

  var header = ht.getColHeader(),
    posColCond = header.indexOf(o.whereCol),
    posCol = header.indexOf(o.col),
    valCondAll = ht.getDataAtCol(posColCond),
    valAll = ht.getDataAtCol(posCol);
  o.whereOp = o.whereOp || "==";

  posColCond = ifNotEmpty(posColCond,posColCond,o.whereCol);
  posCol = ifNotEmpty(posCol,posCol,o.col);

  var w = newWorker(workerSetColCond);
  // handle message received
  w.onmessage = function(e) {
    var m = e.data;
    if (m.progress && o.elProgress) {
      o.elProgress.innerText = Math.round(m.progress) + "%";
    }
    if (m.result) {
      if(o.elProgress) o.elProgress.innerText="";
      ht.setDataAtCell(m.result);
    }
  };
  // launch process
  w.postMessage({
    targetArray: valAll,
    filterArray: valCondAll,
    setValue: o.set,
    filterValue: o.whereVal,
    targetCol: posCol,
    filterCol: posColCond,
    operator: o.whereOp
  });
}



/**
* Test if number
* @param {*} n Test if n is a number
*/
function isNumber(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}



/**
* Test for empty, return b if true, if not
* @param {Boolean} a Condition
* @param {*} b Object to return if true
* @param {*} b Object to return if false
*/
function ifNotEmpty(a, b, c) {
  var tA = typeof a;
  if (tA != "undefined" || tA == "number" || (tA == "string" && a.length > 0)) {
    return b;
  } else {
    return c;
  }
}


/**
* Get object with label and value key from table headers
* @param {Object}  hot handsontable object
*/
function getHeaderObj(hot) {
  var out = [];
  var headers = hot.getColHeader();
  for (var i = 0, iL = headers.length; i < iL; i++) {
    out.push({
      label: headers[i],
      value: i
    });
  }
  return out;
}


/**
* Create an element
* @param  {String} t Type of element to create
*/
function elCreate(t) {
  return document.createElement(t);
}


function hasValue(x){
 return x || x === 0;
}

function filterArray(arr) {
    var index = -1,
        arrLength = arr ? arr.length : 0,
        resIndex = -1,
        result = [];

    while (++index < arrLength) {
        var value = arr[index];
        if (hasValue(value)) {
            result[++resIndex] = value;
        }
    }

    return result;
}

/**
* Create a select drop down list based on an array or an array of object 
* @param {Array} arr Array of number, string or object with value / label keys
* @param {String} id optional id for the select element
*/
function selectCreate(arr, id) {
  var opt, item, value, label;
  var out = {};
  arr = filterArray(arr);

  /**
  * Sort by label or value
  */

  arr = arr.sort(function(a, b) {
    if (ifNotEmpty(a&&a.label,a.label,a) < ifNotEmpty(b&&b.label,b.label,b))
      return -1;
    if (ifNotEmpty(a&&a.label,a.label,a) > ifNotEmpty(b&&b.label,b.label,b))
      return 1;
    return 0;
  });

  var sel = elCreate("select");
  if (id) sel.id = id;
  var seen = [];

  /**
  * Populate options
  */
  for (var i = 0, iL = arr.length; i < iL; i++) {
    item = arr[i];
    if (seen.indexOf(item) == -1) {
      seen.push(item);
      opt = elCreate("option");
      label = ifNotEmpty(item.label, item.label, item);
      value = ifNotEmpty(item.value, item.value, item);
      opt.innerText = label;
      opt.dataset.opt = JSON.stringify({
        value: value
      });
      sel.appendChild(opt);
    }
  }
  return sel;
} 
