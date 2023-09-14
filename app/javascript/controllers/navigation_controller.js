import { Controller } from "stimulus";

export default class extends Controller {
  // static targets = ['form'];
  connect() {
    console.log(document.body.scrollTop);
  }

  topFunction() {
    document.body.scrollTop = 0; // For Safari
    document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
  };

  backFunction() {
    document.body.scrollTop = document.scrollHeight; // For Safari
    document.documentElement.scrollTop = document.documentElement.scrollHeight; // For Chrome, Firefox, IE and Opera
  };

  backToBottom(){
    console.log("back to bottom" );
    document.getElementById("bottom").scrollIntoView({ behavior: "smooth" })
    window.scrollBy(0, -143);
  }
}
