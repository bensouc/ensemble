//Get the button:
const mybutton = document.getElementById("back-to-top-btn");
const backToBottomBtn = document.getElementById("backToBottomBtn");
mybutton.onclick = function () { topFunction() };
backToBottomBtn.onclick = function () { backFunction() };
// When the user scrolls down 200px from the top of the document, show the button
window.onscroll = function () { scrollFunction() };

const scrollFunction = () => {
  // console.log('scrolling')
  // console.log(document.documentElement.scrollTop)
  if (document.body.scrollTop > 100 || document.documentElement.scrollTop > 100) {
    mybutton.style.transition = 1;
    mybutton.style.display = "block";
    console.log('disparu')
    backToBottomBtn.style.transition = 1;
    backToBottomBtn.style.display = "block";
  } else {
    mybutton.style.transition = 1;
    mybutton.style.display = "none";
    backToBottomBtn.style.transition = 1;
    backToBottomBtn.style.display = "none";
  }
};

// When the user clicks on the button, scroll to the top of the document
const topFunction = () => {
  document.body.scrollTop = 0; // For Safari
  document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
};

const backFunction = () => {
  document.body.scrollTop = document.scrollHeight; // For Safari
  document.documentElement.scrollTop = document.documentElement.scrollHeight; // For Chrome, Firefox, IE and Opera
};
