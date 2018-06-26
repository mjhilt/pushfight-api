/*
// By Simon Sarris
// www.simonsarris.com
// sarris@acm.org
//
// Last update December 2011
//
// Free to use and distribute at will
// So long as you are nice to people, etc

// Constructor for Shape objects to hold data for all drawn objects.
// For now they will just be defined as rectangles.
function Shape(x, y, w, h, fill) {
    // This is a very simple and unsafe constructor. All we're doing is checking if the values exist.
    // "x || 0" just means "if there is a value for x, use that. Otherwise use 0."
    // But we aren't checking anything else! We could put "Lalala" for the value of x 
    this.x = x || 0;
    this.y = y || 0;
    this.w = w || 1;
    this.h = h || 1;
    this.fill = fill || '#AAAAAA';
}

// Draws this shape to a given context
Shape.prototype.draw = function (ctx) {
    ctx.fillStyle = this.fill;
    ctx.fillRect(this.x, this.y, this.w, this.h);
}

// Determine if a point is inside the shape's bounds
Shape.prototype.contains = function (mx, my) {
    // All we have to do is make sure the Mouse X,Y fall in the area between
    // the shape's X and (X + Width) and its Y and (Y + Height)
    return (this.x <= mx) && (this.x + this.w >= mx) &&
        (this.y <= my) && (this.y + this.h >= my);
}

function CanvasState(canvas) {
    // **** First some setup! ****

    this.canvas = canvas;
    this.width = canvas.width;
    this.height = canvas.height;
    this.ctx = canvas.getContext('2d');
    // This complicates things a little but but fixes mouse co-ordinate problems
    // when there's a border or padding. See getMouse for more detail
    var stylePaddingLeft, stylePaddingTop, styleBorderLeft, styleBorderTop;
    if (document.defaultView && document.defaultView.getComputedStyle) {
        this.stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingLeft'], 10) || 0;
        this.stylePaddingTop = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingTop'], 10) || 0;
        this.styleBorderLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderLeftWidth'], 10) || 0;
        this.styleBorderTop = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderTopWidth'], 10) || 0;
    }
    // Some pages have fixed-position bars (like the stumbleupon bar) at the top or left of the page
    // They will mess up mouse coordinates and this fixes that
    var html = document.body.parentNode;
    this.htmlTop = html.offsetTop;
    this.htmlLeft = html.offsetLeft;

    // **** Keep track of state! ****

    this.valid = false; // when set to false, the canvas will redraw everything
    this.shapes = [];  // the collection of things to be drawn
    this.dragging = false; // Keep track of when we are dragging
    // the current selected object. In the future we could turn this into an array for multiple selection
    this.selection = null;
    this.dragoffx = 0; // See mousedown and mousemove events for explanation
    this.dragoffy = 0;

    // **** Then events! ****

    // This is an example of a closure!
    // Right here "this" means the CanvasState. But we are making events on the Canvas itself,
    // and when the events are fired on the canvas the variable "this" is going to mean the canvas!
    // Since we still want to use this particular CanvasState in the events we have to save a reference to it.
    // This is our reference!
    var myState = this;

    //fixes a problem where double clicking causes text to get selected on the canvas
    canvas.addEventListener('selectstart', function (e) { e.preventDefault(); return false; }, false);
    // Up, down, and move are for dragging
    canvas.addEventListener('mousedown', function (e) {
        var mouse = myState.getMouse(e);
        var mx = mouse.x;
        var my = mouse.y;
        var shapes = myState.shapes;
        var l = shapes.length;
        for (var i = l - 1; i >= 0; i--) {
            if (shapes[i].contains(mx, my)) {
                var mySel = shapes[i];
                // Keep track of where in the object we clicked
                // so we can move it smoothly (see mousemove)
                myState.dragoffx = mx - mySel.x;
                myState.dragoffy = my - mySel.y;
                myState.dragging = true;
                myState.selection = mySel;
                myState.valid = false;
                return;
            }
        }
        // havent returned means we have failed to select anything.
        // If there was an object selected, we deselect it
        if (myState.selection) {
            myState.selection = null;
            myState.valid = false; // Need to clear the old selection border
        }
    }, true);
    canvas.addEventListener('mousemove', function (e) {
        if (myState.dragging) {
            var mouse = myState.getMouse(e);
            // We don't want to drag the object by its top-left corner, we want to drag it
            // from where we clicked. Thats why we saved the offset and use it here
            myState.selection.x = mouse.x - myState.dragoffx;
            myState.selection.y = mouse.y - myState.dragoffy;
            myState.valid = false; // Something's dragging so we must redraw
        }
    }, true);
    canvas.addEventListener('mouseup', function (e) {
        myState.dragging = false;
    }, true);
    // double click for making new shapes
    canvas.addEventListener('dblclick', function (e) {
        var mouse = myState.getMouse(e);
        myState.addShape(new Shape(mouse.x - 10, mouse.y - 10, 20, 20, 'rgba(0,255,0,.6)'));
    }, true);

    // **** Options! ****

    this.selectionColor = '#CC0000';
    this.selectionWidth = 2;
    this.interval = 30;
    setInterval(function () { myState.draw(); }, myState.interval);
}

CanvasState.prototype.addShape = function (shape) {
    this.shapes.push(shape);
    this.valid = false;
}

CanvasState.prototype.clear = function () {
    this.ctx.clearRect(0, 0, this.width, this.height);
}

// While draw is called as often as the INTERVAL variable demands,
// It only ever does something if the canvas gets invalidated by our code
CanvasState.prototype.draw = function () {
    // if our state is invalid, redraw and validate!
    if (!this.valid) {
        var ctx = this.ctx;
        var shapes = this.shapes;
        this.clear();

        // ** Add stuff you want drawn in the background all the time here **

        // draw all shapes
        var l = shapes.length;
        for (var i = 0; i < l; i++) {
            var shape = shapes[i];
            // We can skip the drawing of elements that have moved off the screen:
            if (shape.x > this.width || shape.y > this.height ||
                shape.x + shape.w < 0 || shape.y + shape.h < 0) continue;
            shapes[i].draw(ctx);
        }

        // draw selection
        // right now this is just a stroke along the edge of the selected Shape
        if (this.selection != null) {
            ctx.strokeStyle = this.selectionColor;
            ctx.lineWidth = this.selectionWidth;
            var mySel = this.selection;
            ctx.strokeRect(mySel.x, mySel.y, mySel.w, mySel.h);
        }

        // ** Add stuff you want drawn on top all the time here **

        this.valid = true;
    }
}


// Creates an object with x and y defined, set to the mouse position relative to the state's canvas
// If you wanna be super-correct this can be tricky, we have to worry about padding and borders
CanvasState.prototype.getMouse = function (e) {
    var element = this.canvas, offsetX = 0, offsetY = 0, mx, my;

    // Compute the total offset
    if (element.offsetParent !== undefined) {
        do {
            offsetX += element.offsetLeft;
            offsetY += element.offsetTop;
        } while ((element = element.offsetParent));
    }

    // Add padding and border style widths to offset
    // Also add the <html> offsets in case there's a position:fixed bar
    offsetX += this.stylePaddingLeft + this.styleBorderLeft + this.htmlLeft;
    offsetY += this.stylePaddingTop + this.styleBorderTop + this.htmlTop;

    mx = e.pageX - offsetX;
    my = e.pageY - offsetY;

    // We return a simple javascript object (a hash) with x and y defined
    return { x: mx, y: my };
}

// If you dont want to use <body onLoad='init()'>
// You could uncomment this init() reference and place the script reference inside the body tag
//init();

function init() {
    var s = new CanvasState(document.getElementById("game-of-life-canvas"));
    s.addShape(new Shape(40, 40, 50, 50)); // The default is gray
    s.addShape(new Shape(60, 140, 40, 60, 'lightskyblue'));
    // Lets make some partially transparent
    s.addShape(new Shape(80, 150, 60, 30, 'rgba(127, 255, 212, .5)'));
    s.addShape(new Shape(125, 80, 30, 80, 'rgba(245, 222, 179, .7)'));
}

init()
*/
// Now go make something amazing!

// /*
import { memory } from "./wasm_game_of_life_bg";
import { Universe } from "./wasm_game_of_life";
// TODO make sure all pixels are ints
const CELL_SIZE = 100; // px
const GRID_COLOR = "#CCCCCC";
const EMPTY_COLOR = "#808080";
const WHITE_COLOR = "#FFFFFF";
const BLACK_COLOR = "#000000";
const ABYSS_COLOR = "#0047AB";

const WHITE_PUSHER = 0;
const WHITE_MOVER = 1;
const BLACK_PUSHER = 2;
const BLACK_MOVER = 3;
const EMPTY = 4;
const ABYSS = 5;

// These must match `Cell::Alive` and `Cell::Dead` in `src/lib.rs`.
// const DEAD = 5;
// const ALIVE = 1;


// Construct the universe, and get its width and height.
const universe = Universe.new();
const width = universe.width();
const height = universe.height();

// Give the canvas room for all of our cells and a 1px border
// around each of them.
const canvas = document.getElementById("game-of-life-canvas");
canvas.height = (CELL_SIZE + 1) * height + 1;
canvas.width = (CELL_SIZE + 1) * width + 1;

const ctx = canvas.getContext('2d');

const renderLoop = () => {
    
    // universe.tick();
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drawGrid();
    drawCells();
    
    requestAnimationFrame(renderLoop);
};
requestAnimationFrame(renderLoop)
// setInterval(function () { renderLoop(); }, 30);

function writeMessage(canvas, message) {
    var context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.font = '18pt Calibri';
    context.fillStyle = 'black';
    context.fillText(message, 10, 25);
}
function getMousePos(canvas, evt) {
    var rect = canvas.getBoundingClientRect();
    return {
        x: evt.clientX - rect.left,
        y: evt.clientY - rect.top
    };
}
var mouseDownPos = null;
var lastMousePos = null;
canvas.addEventListener('mousedown', function (evt) {
    var mousePos = getMousePos(canvas, evt);
    mouseDownPos = mousePos;
    lastMousePos = mousePos;
}, true)

canvas.addEventListener('mousemove', function (evt) {
    var mousePos = getMousePos(canvas, evt);
    var message = 'Mouse position: ' + mousePos.x + ',' + mousePos.y;
    // console.log(message);
    lastMousePos = mousePos;
}, true);
canvas.addEventListener('selectstart', function (e) { e.preventDefault(); return false; }, false);
canvas.addEventListener('mouseup', function (evt) {
    var mousePos = getMousePos(canvas, evt);
    lastMousePos = mousePos;
    mouseDownPos = null;
}, true)

const drawGrid = () => {
    ctx.beginPath();
    ctx.lineWidth = 1 / window.devicePixelRatio;
    ctx.strokeStyle = GRID_COLOR;

    // Vertical lines.
    for (let i = 0; i <= width; i++) {
        ctx.moveTo(i * (CELL_SIZE + 1) + 1, 0);
        ctx.lineTo(i * (CELL_SIZE + 1) + 1, (CELL_SIZE + 1) * height + 1);
    }

    // Horizontal lines.
    for (let j = 0; j <= height; j++) {
        ctx.moveTo(0, j * (CELL_SIZE + 1) + 1);
        ctx.lineTo((CELL_SIZE + 1) * width + 1, j * (CELL_SIZE + 1) + 1);
    }

    ctx.stroke();
};

const getIndex = (row, column) => {
    return row * width + column;
};

const drawSquare = (row, col, cell_type, offset) => {
    if (cell_type === WHITE_PUSHER || cell_type === WHITE_MOVER) {
        ctx.fillStyle = WHITE_COLOR;
    }
    else if (cell_type === BLACK_PUSHER || cell_type === BLACK_MOVER) {
        ctx.fillStyle = BLACK_COLOR;
    }
    else if (cell_type === EMPTY) {
        ctx.fillStyle = EMPTY_COLOR;
    }
    else {
        ctx.fillStyle = ABYSS_COLOR;
    }

    if (cell_type === BLACK_MOVER || cell_type === WHITE_MOVER) {
        ctx.beginPath();
        ctx.arc(
            offset.x + col * (CELL_SIZE + 1) + 1 + CELL_SIZE / 2,
            offset.y + row * (CELL_SIZE + 1) + 1 + CELL_SIZE / 2,
            CELL_SIZE / 2,
            0, 2 * Math.PI, false);
        ctx.fill();
        // ctx.lineWidth = 1;
        // ctx.strokeStyle = BLACK_COLOR;
        // ctx.stroke();
    }
    else {
        ctx.beginPath();
        ctx.rect(
            offset.x + col * (CELL_SIZE + 1) + 1,
            offset.y + row * (CELL_SIZE + 1) + 1,
            CELL_SIZE,
            CELL_SIZE
        );
        ctx.fill();
        if (cell_type === BLACK_PUSHER || cell_type === WHITE_PUSHER) {
            ctx.lineWidth = 1;
            // ctx.strokeStyle = BLACK_COLOR;
            // ctx.stroke();
        }
    }
}
const drawCells = () => {
    const cellsPtr = universe.cells();
    const cells = new Uint8Array(memory.buffer, cellsPtr, width * height);

    ctx.beginPath();

    var defer = null;
    for (let row = 0; row < height; row++) {
        for (let col = 0; col < width; col++) {
            const idx = getIndex(row, col);
            drawSquare(row, col, EMPTY, { x: 0, y: 0 });

            if (mouseDownPos !== null
            && lastMousePos !== null
            && Math.floor(mouseDownPos.x / (CELL_SIZE + 1)) === col
            && Math.floor(mouseDownPos.y / (CELL_SIZE + 1)) === row
            && (cells[idx] === WHITE_PUSHER
                || cells[idx] === WHITE_MOVER
                || cells[idx] === BLACK_PUSHER
                || cells[idx] === BLACK_MOVER)) {
                    var offset = { x: lastMousePos.x - mouseDownPos.x, y: lastMousePos.y - mouseDownPos.y};
                    defer = {row: row, col: col, offset: offset, cell_type: cells[idx]};
            }
            else
            {
                drawSquare(row, col, cells[idx], { x: 0, y: 0 });
            }
        }
    }
    // console.log(defer)
    if (defer) {
        drawSquare(defer.row, defer.col, EMPTY, { x: 0, y: 0 });
        drawSquare(defer.row, defer.col, defer.cell_type, defer.offset);
    }
    // ctx.stroke();
};

// requestAnimationFrame(renderLoop);

// const canvas = document.getElementById("game-of-life-canvas");
// const universe = Universe.new();
// canvas.textContent = universe.render();

// function writeMessage(canvas, message) {
//     var context = canvas.getContext('2d');
//     context.clearRect(0, 0, canvas.width, canvas.height);
//     context.font = '18pt Calibri';
//     context.fillStyle = 'black';
//     context.fillText(message, 10, 25);
// }
// function getMousePos(canvas, evt) {
//     var rect = canvas.getBoundingClientRect();
//     return {
//         x: evt.clientX - rect.left,
//         y: evt.clientY - rect.top
//     };
// }
// // var canvas = document.getElementById('pre');
// var context = canvas.getContext('2d');

// canvas.addEventListener('mousemove', function (evt) {
//     var mousePos = getMousePos(canvas, evt);
//     var message = 'Mouse position: ' + mousePos.x + ',' + mousePos.y;
//     writeMessage(canvas, message);
// }, false);
//     </script >
//   </body >
// // const renderLoop = () => {
// //     pre.textContent = universe.render();
// //     // universe.tick();

// //     requestAnimationFrame(renderLoop);
// // };
// // requestAnimationFrame(renderLoop);
// */