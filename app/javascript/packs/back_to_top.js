
  scrollFunction = function() {
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
    if ((document.documentElement.scrollTop < (document.documentElement.scrollHeight - 1100)) ) {
      backToBottomBtn.style.transition = 1;
      backToBottomBtn.style.display = "block";
      // console.log("c'est display")
    }else {
      // console.log("c'est caché")
      backToBottomBtn.style.transition = 1;
      backToBottomBtn.style.display = "none";
    }
  };

  // When the user clicks on the button, scroll to the top of the document

  // When the user scrolls down 200px from the top of the document, show the button
  window.onscroll = function () { scrollFunction() };

  // document.body.scrollHeight document.documentElement.scrollHeight
