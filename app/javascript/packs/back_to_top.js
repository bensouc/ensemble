
  scrollFunction = function() {
    //Get the button:
    const myButton = document.getElementById("backToTopBtn");
    const backToBottomBtn = document.getElementById("backToBottomBtn");
    // console.log(document.documentElement.scrollTop)
    if (document.body.scrollTop > 100 || document.documentElement.scrollTop > 100) {
      myButton.style.transition = 1;
      myButton.style.display = "block";
      backToBottomBtn.style.transition = 1;
      backToBottomBtn.style.display = "block";
    } else {
      myButton.style.transition = 1;
      myButton.style.display = "none";
      backToBottomBtn.style.transition = 1;
      backToBottomBtn.style.display = "none";
    }
  };

  // When the user clicks on the button, scroll to the top of the document

  // When the user scrolls down 200px from the top of the document, show the button
  window.onscroll = function () { scrollFunction() };
