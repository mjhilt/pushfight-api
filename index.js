
import { memory } from "./wasm_game_of_life_bg";
import { Universe } from "./wasm_game_of_life";
// TODO make sure all pixels are ints
const CELL_SIZE = 100; // px
const GRID_COLOR = "#CCCCCC";
const EMPTY_COLOR = "#808080";
const WHITE_COLOR = "#FFFFFF";
const BLACK_COLOR = "#000000";
const ABYSS_COLOR = "#0047AB";
const ANCHOR_COLOR = "#FF0000";

const WHITE_PUSHER = 0;
const WHITE_MOVER = 1;
const BLACK_PUSHER = 2;
const BLACK_MOVER = 3;
const EMPTY = 4;
const ABYSS = 5;
const ANCHORED_WHITE_PUSHER = 6;
const ANCHORED_BLACK_PUSHER = 7;

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
    if (mouseDownPos !== null) {
        var start_row = Math.floor(mouseDownPos.y/CELL_SIZE);
        var start_col = Math.floor(mouseDownPos.x/CELL_SIZE);
        var end_row = Math.floor(lastMousePos.y/CELL_SIZE);
        var end_col = Math.floor(lastMousePos.x/CELL_SIZE);
        // universe = universe.try_move(start_row, start_col, end_row, end_col);   
        universe.try_move(start_row, start_col, end_row, end_col);
    }
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
    if (cell_type === WHITE_PUSHER || cell_type === WHITE_MOVER || cell_type == ANCHORED_WHITE_PUSHER) {
        ctx.fillStyle = WHITE_COLOR;
    }
    else if (cell_type === BLACK_PUSHER || cell_type === BLACK_MOVER || cell_type == ANCHORED_BLACK_PUSHER) {
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
        }
    }
}

const drawAnchor = (row, col, cell_type, offset) => {
    if (cell_type === ANCHORED_BLACK_PUSHER || cell_type === ANCHORED_WHITE_PUSHER) {
        ctx.fillStyle = ANCHOR_COLOR;
        ctx.beginPath();
        ctx.arc(
            offset.x + col * (CELL_SIZE + 1) + 1 + CELL_SIZE / 2,
            offset.y + row * (CELL_SIZE + 1) + 1 + CELL_SIZE / 2,
            Math.round(CELL_SIZE / 4),
            0, 2 * Math.PI, false);
        ctx.fill();
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
                || cells[idx] === ANCHORED_BLACK_PUSHER
                || cells[idx] === ANCHORED_WHITE_PUSHER
                || cells[idx] === BLACK_PUSHER
                || cells[idx] === BLACK_MOVER)) {
                    var offset = { x: lastMousePos.x - mouseDownPos.x, y: lastMousePos.y - mouseDownPos.y};
                    defer = {row: row, col: col, offset: offset, cell_type: cells[idx]};
            }
            else
            {
                drawSquare(row, col, cells[idx], { x: 0, y: 0 });
                drawAnchor(row, col, cells[idx], { x: 0, y: 0 });
            }
            
        }
    }
    if (defer) {
        drawSquare(defer.row, defer.col, EMPTY, { x: 0, y: 0 });
        drawSquare(defer.row, defer.col, defer.cell_type, defer.offset);
    }
};
