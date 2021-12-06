if (typeof type == 'undefined' || !type) type = "day";
if (typeof author == 'undefined' || !author) author = '';
if (typeof theme == 'undefined' || !theme) theme = '';
if (typeof word == 'undefined' || !word) word = '';

//var src='https://citations.ouest-france.fr/apis/export.php?t='+escape(type);
//var src='http://local.citation-du-jour.fr/apis/export.php?t='+escape(type)+'&author='+author+'&theme='+theme+'&word='+word;

var request = new XMLHttpRequest();
request.open('GET', 'https://citations.ouest-france.fr/apis/export.php?json&key=464fzer5&t=' + escape(type) + '&author=' + author + '&theme=' + theme + '&word=' + word, true);
request.send(null);

request.onload = function () {
  if (request.status >= 200 && request.status < 400) {
    var data = JSON.parse(request.responseText);
    content = `<div> ${data.quote} <br> <em>${data.name}</em></div>`;
    document.getElementById('QuoteOFDay').innerHTML = content;
  }
};
