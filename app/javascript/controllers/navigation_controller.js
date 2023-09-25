import { Controller } from "stimulus";

export default class extends Controller {
  // static targets = ['form'];
  connect() {
    // console.log(document.body.scrollTop);
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

  scrollFunction () {
    //Get the button:
    const myButton = document.getElementById("backToTopBtn");
    const backToBottomBtn = document.getElementById("backToBottomBtn");
    // console.log(document.documentElement.scrollTop) rmove document.documentElement.scrollHeight becaus its work on edge
    if (document.documentElement.scrollTop > 100) {
      myButton.style.transition = 1;
      myButton.style.display = "block";
      // backToBottomBtn.style.transition = 1;
      // backToBottomBtn.style.display = "block";
    } else {
      myButton.style.transition = 1;
      myButton.style.display = "none";
      // backToBottomBtn.style.transition = 1;
      // backToBottomBtn.style.display = "none";
    };
    // remove || (document.body.scrollTop < (document.body.scrollHeight - 1500)) from test it works on edge
    if ((document.documentElement.scrollTop < (document.documentElement.scrollHeight - 1100))) {
      backToBottomBtn.style.transition = 1;
      backToBottomBtn.style.display = "block";
      // console.log("c'est display")
    } else {
      // console.log("c'est caché")
      backToBottomBtn.style.transition = 1;
      backToBottomBtn.style.display = "none";
    }
  };
}
