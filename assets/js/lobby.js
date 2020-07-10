import {Presence} from "phoenix" //presence

let Lobby = {

    init(socket, element) {if(!element) {return}
        socket.connect()
        let userId = element.getAttribute("data-user-id") //userid
        this.onReady(userId, socket) //dodan userid
    },

    onReady(userId, socket){ //dodan userId za userchannel
        let chat = document.getElementById("lobby-chat")
        let msgInput = document.getElementById("message-input")
        let sendButton = document.getElementById("send-message")
        let channel_lobby = socket.channel("lobby")
        let channel_user = socket.channel("user:" + userId) //userchannel
        let userList = document.getElementById("online") //presence
        let channel_invite = null // kod accepta i rejecta
        let canceled = false //da ne bude cancel -> reject -> rejected
        let timeout = null //kasnije za invite
        let inviterId = null //kasnije za id-eve source i dest
        let available = true

        //presence
        let presence = new Presence(channel_lobby)
        presence.onSync(() => {
            // userList.innerHTML = presence.list((id) => {
            userList.innerHTML = presence.list((id, {user: user}) => {
                // return `<li>${user.username}</li>`}).join("")
                if (userId == id) return //userid da ne vrati gumb za sebe
                return `<button id="invite-${id}">${user.username}</button>`}).join(" ")
            presence.list((id) => {
                if (userId == id) return
                let button = document.getElementById(`invite-${id}`)
                button.addEventListener("click", e => {
                    // this.Invite(id, socket) //kad accept i reject
                    available = false
                    channel_invite = this.Invite(userId, id, socket)
                })
            })
        })

        msgInput.addEventListener("keypress" , e => {
            if (e.keyCode == 13 && msgInput.value.length > 0){
                this.SendMessage(channel_lobby)
            }
        })

        sendButton.addEventListener("click", e => {
            if (msgInput.value.length > 0)
                this.SendMessage(channel_lobby)
        })

        channel_lobby.on("new_message", resp => {
            this.RenderMessage(chat, resp)
        })

        channel_user.on("invite", resp => {
            if (resp.dest_id != userId) return
            if (inviterId != null || !available) {
                console.log(`invite reject ${resp.user.username} busy`)
                let payload = {sourceId: userId, destId: resp.source_id}
                channel_user.push("reject", payload)
                    .receive("error", e => console.log(e))
                return
            }
            available = false
            inviterId = resp.source_id
            let inviteDialog = document.getElementById("inviteDialog")
            let inviteText = document.getElementById("invite-text")
            inviteText.innerHTML = `${resp.user.username} invited you to a game.
                <br>
                Do you wish to accept?`
            inviteDialog.style.display = "block";
            
            timeout = setTimeout(function() {
                console.log("reject because of timeout")
                document.getElementById("rejectBtn").click()
            }, 10000)
        })

        channel_user.on("cancel", function(){
            console.log("invite was canceled")
            canceled = true
            document.getElementById("rejectBtn").click()
        })

        let waitingDialog = document.getElementById("waitingDialog")
        waitingDialog.addEventListener("close", function(){
            available = true
            waitingDialog.style.display = "none"
        })

        channel_user.on("accept", resp => {
            if(resp.source_id == userId) {
            window.location.href = "/match/" + resp.match_id
            }
        })

        let acceptButton = document.getElementById("acceptBtn")
        acceptButton.addEventListener("click", function(){
            clearTimeout(timeout)
            let payload = {sourceId: userId, destId: inviterId}
            console.log("invite accept")
            channel_user.push("accept", payload)
            .receive("error", e => console.log(e))
            inviteDialog.style.display = "none"
        })

        let rejectButton = document.getElementById("rejectBtn")
        rejectButton.addEventListener("click", function(){
            clearTimeout(timeout)
            let payload = {sourceId: userId, destId: inviterId}
            inviterId = null
            available = true
            if (canceled) {
                canceled = false
                inviteDialog.style.display = "none"
                return
            }
            console.log("invite reject")
            channel_user.push("reject", payload)
            .receive("error", e => console.log(e))
            inviteDialog.style.display = "none"
        })

        channel_lobby.join().receive("ok", resp => console.log("joined lobby", resp))
            .receive("error", reason => console.log("failed lobby", reason))
        //user channel
        channel_user.join().receive("ok", resp => console.log("joined user" + userId, resp))
        .receive("error", reason => console.log("failed user" + userId, reason))
    },

    SendMessage(channel_lobby){
        let msgInput = document.getElementById("message-input")
        let payload = {body: msgInput.value}
        channel_lobby.push("new_message", payload)
                .receive("error", e => console.log(e))
        msgInput.value = ""
    },

    esc(str){
        let div = document.createElement("div")
        div.appendChild(document.createTextNode(str))
        return div.innerHTML
    },

    RenderMessage(chat, {user, body}){
        let template = document.createElement("div")
        template.innerHTML =`
        <b>${this.esc(user.username)}</b>: ${this.esc(body)}
        `
        chat.appendChild(template)
        chat.scrollTop = chat.scrollHeight
    },

    Invite(userId, id, socket){
        let payload = {sourceId: userId, destId: id}
        let channel_invite = socket.channel("user:" + id)
        channel_invite.join().receive("ok", resp => console.log("joined user" + id, resp))
            .receive("error", reason => {
                console.log("failed user" + id, reason)
            })
        channel_invite.push("invite", payload)
            .receive("error", e => {
                console.log(e)
                channel_invite.leave()
            })
        console.log("invited" + id)
        let waitingDialog = document.getElementById("waitingDialog")
        waitingDialog.style.display = "block"
        const event = new Event("close")
        let cancelButton = document.getElementById("cancelBtn")
        cancelButton.addEventListener("click", function(){
            channel_invite.push("cancel", payload)
                .receive("error", e => {
                    console.log(e)
                    channel_invite.leave()
                })
            waitingDialog.dispatchEvent(event)
        })
        channel_invite.on("reject", resp => {
            if(resp.dest_id != userId || resp.source_id != id) return
            waitingDialog.dispatchEvent(event)
            console.log("leave on reject")
            channel_invite.leave()
        })
        channel_invite.on("accept", resp => {
            if(resp.dest_id != userId || resp.source_id != id) return
            window.location.href = "/match/" + resp.match_id
            waitingDialog.dispatchEvent(event)
            console.log("leave on accept")
            channel_invite.leave()
        })
        return channel_invite
    }
}
export default Lobby