let Match = {

    init(socket, element) {if(!element) {return}
        socket.connect()
        let userId = element.getAttribute("data-user-id") //userid
        let matchId = element.getAttribute("data-match-id") //matchid
        let whiteId = element.getAttribute("data-white-id") //whiteid
        let blackId = element.getAttribute("data-black-id") //blackid
        let boardString = element.getAttribute("data-board") //board
        let extraTurn = element.getAttribute("data-extra-turn")
        let turnId = element.getAttribute("data-turn-id")
        this.onReady(userId, matchId, whiteId, blackId, boardString, extraTurn, turnId, socket) //dodan userid
    },

    onReady(userId, matchId, whiteId, blackId, boardString, extraTurn, turnId, socket){
        let board = []
        let myTurn = userId == turnId
        let extra = extraTurn
        let turn = document.getElementById("turn")
        turn.innerHTML = this.whoseTurn(userId, whiteId, blackId, turnId)
        let selected = null
        for (let i = 0; i < 8; i++){
            board[i] = []
            for (let j = 0; j < 8; j++){
                board[i][j] = document.getElementById("" + i + j)
            }
        }

        let positions = this.getPositions(boardString)
        this.drawPieces(board, positions)

        let channel = socket.channel("match:" + matchId)
        channel.on("move", resp => console.log(resp))
        channel.join().receive("ok", resp => console.log("joined match" + matchId, resp))
        .receive("error", reason => console.log("failed match" + matchId, reason))
        
        channel.on("move", resp => {
            positions = this.getPositions(resp.board_string)
            this.drawPieces(board, positions)
            myTurn = userId == resp.turn_id
            turn.innerHTML = this.whoseTurn(userId, resp.white_id, resp.black_id, resp.turn_id)
            extra = resp.extra_turn
            if (myTurn && extra != "n"){
                selected = {x: Number(extra[0]), y: Number(extra[1])}
                let piece = positions[extra[0]][extra[1]]
                this.showPossibleMoves(board, positions, selected, piece, true)
            }
            if (resp.winner_id != null){
                if (userId != resp.white_id && userId != resp.black_id){
                    let winner = resp.winner_id == resp.white_id ? "White" : "Black"
                    window.alert(winner + " won!")
                    window.location.href = "/lobby"
                }
                else{
                    if (userId == resp.winner_id){
                        window.alert("Congratulations. You won!")
                        window.location.href = "/lobby"
                    }
                    else{
                        window.alert("You lost. Better luck next time.")
                        window.location.href = "/lobby"
                    }
                }
            }
        })

        if (userId != whiteId && userId != blackId) return

        let pawn = userId == whiteId ? "w" : "b"
        let king = userId == whiteId ? "W" : "B"
        if (myTurn && extra != "n"){
            selected = {x: Number(extra[0]), y: Number(extra[1])}
            let piece = positions[extra[0]][extra[1]]
            this.showPossibleMoves(board, positions, selected, piece, true)
        }

        let surrender = document.getElementById("surrender")
        surrender.addEventListener("click", e => {
            if(confirm("Do you really wish to surrender?")){
                let payload = {matchId: matchId}
                channel.push("surrender", payload)
                .receive("error", e => console.log(e))
            }
        })

        for(let i = 0; i < 8; i++){
            for(let j = 0; j < 8; j++){
                board[i][j].addEventListener("click", e => {
                    if (myTurn && extra == "n"){
                        if (selected == null && (positions[i][j] == pawn || positions[i][j] == king)){
                            selected = {x: Number(i), y: Number(j)}
                            let piece = positions[i][j]
                            this.showPossibleMoves(board, positions, selected, piece, false)
                        }
                        else {
                            if (selected != null){
                                let payload = {oldCoord: selected, newCoord: {x: Number(i), y: Number(j)}, matchId: matchId}
                                selected = null
                                this.resetPossibleMoves(board)
                                channel.push("move", payload)
                                    .receive("error", e => console.log(e))
                            }
                            else {
                                selected = null
                                this.resetPossibleMoves(board)
                            }
                        }
                    }
                    else if (myTurn && extra != "n"){
                        if (selected == null  && i == extra[0] && j == extra[1]){
                            selected = {x: Number(i), y: Number(j)}
                            let piece = positions[i][j]
                            this.showPossibleMoves(board, positions, selected, piece, true)
                        }
                        else if(selected != null){
                            let payload = {oldCoord: selected, newCoord: {x: Number(i), y: Number(j)}, matchId: matchId}
                            selected = null
                            this.resetPossibleMoves(board)
                            channel.push("move", payload)
                                .receive("error", e => console.log(e))
                        }
                    }
                    else{
                        alert("Wait your turn")
                    }
                })
            }
        }

    },

    getPositions(positions){
        let matrix = positions.split(",")
        for(let i = 0; i < matrix.length; i++){
            matrix[i] = matrix[i].split("")
        }
        return matrix
    },

    drawPieces(board, positions){
        for(let i = 0; i < 8; i++){
            for(let j = 0; j < 8; j++){
                switch(positions[i][j]){
                    case "w":
                        board[i][j].innerHTML = "<img src='/images/white_pawn.png' alt='white pawn' class='piece'/>"
                        break;
                    case "W":
                        board[i][j].innerHTML = "<img src='/images/white_king.png' alt='white king' class='piece'/>"
                        break;
                    case "b":
                        board[i][j].innerHTML = "<img src='/images/black_pawn.png' alt='black pawn' class='piece'/>"
                        break;
                    case "B":
                        board[i][j].innerHTML = "<img src='/images/black_king.png' alt='black king' class='piece'/>"
                        break;
                    case "e":
                        board[i][j].innerHTML = "<img src='/images/empty.png' alt='empty' class='piece'/>"
                        break;
                }
            }
        }
    },

    whoseTurn(userId, whiteId, blackId, turnId){
        if (userId != whiteId && userId != blackId){
            if (turnId == whiteId){
                return "turn: white"
            }
            else {
                return "turn: black"
            }
        }
        else{
            if (turnId == userId){
                return "my turn"
            }
            else {
                return "enemy's turn"
            }
        }
    },

    showPossibleMoves(board, positions, selected, piece, extra){
        let whitePawn = "w"
        let whiteKing = "W"
        let blackPawn = "b"
        let blackKing = "B"
        let enemyPawn = piece == whitePawn || piece == whiteKing ? blackPawn : whitePawn
        let enemyKing = piece == whitePawn || piece == whiteKing ? blackKing : whiteKing
        let empty = "e"

        board[selected.x][selected.y].style.backgroundColor = "#ffcc66"
        
        if (piece == whitePawn){
            if (selected.x + 1 < 8 && !extra){
                if (selected.y + 1 < 8 && positions[selected.x + 1][selected.y + 1] == empty){
                    board[selected.x + 1][selected.y + 1].style.backgroundColor = "#6a8455"
                }
                if (selected.y - 1 >= 0 && positions[selected.x + 1][selected.y - 1] == empty){
                    board[selected.x + 1][selected.y - 1].style.backgroundColor = "#6a8455"
                }
            }
            if (selected.x + 2 < 8){
                if (selected.y + 2 < 8 && positions[selected.x + 2][selected.y + 2] == empty
                && (positions[selected.x + 1][selected.y + 1] == blackPawn || positions[selected.x + 1][selected.y + 1] == blackKing)){
                    board[selected.x + 2][selected.y + 2].style.backgroundColor = "#6a8455"
                    }
                if (selected.y - 2 < 8 && positions[selected.x + 2][selected.y - 2] == empty
                    && (positions[selected.x + 1][selected.y - 1] == blackPawn || positions[selected.x + 1][selected.y - 1] == blackKing)){
                        board[selected.x + 2][selected.y - 2].style.backgroundColor = "#6a8455"
                        }
            }
        }
        else if (piece == blackPawn){
            if (selected.x - 1 >= 0 && !extra){
                if (selected.y + 1 < 8 && positions[selected.x - 1][selected.y + 1] == empty){
                    board[selected.x - 1][selected.y + 1].style.backgroundColor = "#6a8455"
                }
                if (selected.y - 1 >= 0 && positions[selected.x - 1][selected.y - 1] == empty){
                    board[selected.x - 1][selected.y - 1].style.backgroundColor = "#6a8455"
                }
            }
            if (selected.x - 2 >= 0){
                if (selected.y + 2 < 8 && positions[selected.x - 2][selected.y + 2] == empty
                && (positions[selected.x - 1][selected.y + 1] == whitePawn || positions[selected.x - 1][selected.y + 1] == whiteKing)){
                    board[selected.x - 2][selected.y + 2].style.backgroundColor = "#6a8455"
                    }
                if (selected.y - 2 >= 0 && positions[selected.x - 2][selected.y - 2] == empty
                    && (positions[selected.x - 1][selected.y - 1] == whitePawn || positions[selected.x - 1][selected.y - 1] == whiteKing)){
                        board[selected.x - 2][selected.y - 2].style.backgroundColor = "#6a8455"
                        }
            }
        }

        if (piece == whiteKing || piece == blackKing){
            if (selected.x + 1 < 8 && !extra){
                if (selected.y + 1 < 8 && positions[selected.x + 1][selected.y + 1] == empty){
                    board[selected.x + 1][selected.y + 1].style.backgroundColor = "#6a8455"
                }
                if (selected.y - 1 >= 0 && positions[selected.x + 1][selected.y - 1] == empty){
                    board[selected.x + 1][selected.y - 1].style.backgroundColor = "#6a8455"
                }
            }
            if (selected.x + 2 < 8){
                if (selected.y + 2 < 8 && positions[selected.x + 2][selected.y + 2] == empty
                && (positions[selected.x + 1][selected.y + 1] == enemyPawn || positions[selected.x + 1][selected.y + 1] == enemyKing)){
                    board[selected.x + 2][selected.y + 2].style.backgroundColor = "#6a8455"
                    }
                if (selected.y - 2 < 8 && positions[selected.x + 2][selected.y - 2] == empty
                    && (positions[selected.x + 1][selected.y - 1] == enemyPawn || positions[selected.x + 1][selected.y - 1] == enemyKing)){
                        board[selected.x + 2][selected.y - 2].style.backgroundColor = "#6a8455"
                        }
            }
            if (selected.x - 1 >= 0 && !extra){
                if (selected.y + 1 < 8 && positions[selected.x - 1][selected.y + 1] == empty){
                    board[selected.x - 1][selected.y + 1].style.backgroundColor = "#6a8455"
                }
                if (selected.y - 1 >= 0 && positions[selected.x - 1][selected.y - 1] == empty){
                    board[selected.x - 1][selected.y - 1].style.backgroundColor = "#6a8455"
                }
            }
            if (selected.x - 2 >= 0){
                if (selected.y + 2 < 8 && positions[selected.x - 2][selected.y + 2] == empty
                && (positions[selected.x - 1][selected.y + 1] == enemyPawn || positions[selected.x - 1][selected.y + 1] == enemyKing)){
                    board[selected.x - 2][selected.y + 2].style.backgroundColor = "#6a8455"
                    }
                if (selected.y - 2 >= 0 && positions[selected.x - 2][selected.y - 2] == empty
                    && (positions[selected.x - 1][selected.y - 1] == enemyPawn || positions[selected.x - 1][selected.y - 1] == enemyKing)){
                        board[selected.x - 2][selected.y - 2].style.backgroundColor = "#6a8455"
                        }
            }

        }
    },

    resetPossibleMoves(board){
        for(let i = 0; i < 8; i++){
            for(let j = 0; j < 8; j++){
                board[i][j].removeAttribute("style")
            }
        }
    }
}
export default Match