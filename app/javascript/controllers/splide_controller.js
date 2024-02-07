import { Controller } from "stimulus";
import Splide from '@splidejs/splide';
export default class extends Controller {

  connect(){
    // console.log(this.element);
    // console.log('skill-add connected');
    new Splide(this.element,{
                              type: 'loop',
                              speed: 2000,
                              autoplay: true,
                              interval: Math.floor((2000 * (1 + Math.random()))),
                              perPage: 1,
                              arrows: false,
                              pauseOnHover: true,
                            }).mount();
  }

}
