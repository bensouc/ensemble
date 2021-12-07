

const displayQuote = ((event) => {
  console.log('coucou');

  // if (typeof type == 'undefined' || !type) type = "day";
  // if (typeof author == 'undefined' || !author) author = '';
  // if (typeof theme == 'undefined' || !theme) theme = '';
  // if (typeof word == 'undefined' || !word) word = '';

  const type="theme";
  const theme = ['amour','ecologie', 'ecole', 'education', 'enseignement', 'enfance', 'reve', 'connaissance'][Math.floor(Math.random() * 7)];
  const author="";
  const word="";
  console.log(theme)
  //const src='https://citations.ouest-france.fr/apis/export.php?t='+escape(type);
  //const src='http://local.citation-du-jour.fr/apis/export.php?t='+escape(type)+'&author='+author+'&theme='+theme+'&word='+word;

  const request = new XMLHttpRequest();
  request.open('GET', 'https://citations.ouest-france.fr/apis/export.php?json&key=464fzer5&t=' + escape(type) + '&author=' + author + '&theme=' + theme + '&word=' + word, true);
  request.send(null);

  console.log(request)

  request.onload = function () {
    if (request.status >= 200 && request.status < 400) {
      const data = JSON.parse(request.responseText);
      const content = `<div> ${data.quote} <br> <em>${data.name}</em></div>`;
      document.getElementById('QuoteOFDay').innerHTML = content;
    }
  };
})

export { displayQuote }
