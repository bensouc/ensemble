import { Controller } from "stimulus";

export default class extends Controller {


  connect() {
    const anchor = getUrlHash()
    // console.log(anchor)
    if (anchor != false)
    {
      // console.log(anchor);
      const element = document.getElementById(anchor)
      element.classList.toggle("d-none");
    }
  }


}
