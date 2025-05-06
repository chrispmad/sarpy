$( document ).ready(function() {

  // Find the polygon icon div
  poly_icon = document.getElementById('poly_icon_d')
  point_icon = document.getElementById('point_icon_d')

  // Find each dropdown label, appending the icon to the left of the label.
  dropdown_labels = document.getElementById('dataset_sel').children[1].children

  for(let i = 0; i <= 4; i++){
    console.log(dropdown_labels[i].innerText)
    if(dropdown_labels[i].innerText.match(/KFO/g) == 'KFO'){
      icon_to_add = point_icon.cloneNode(true)
    } else {
      icon_to_add = poly_icon.cloneNode(true)
    }
    icon_to_add.id = 'menu_icon_' + i
    icon_to_add.classList.remove('hidden')
    icon_to_add.style.top = dropdown_labels[i].offsetTop - 3 + 'px'
    icon_to_add.style.left = dropdown_labels[i].offsetLeft - 20 + 'px'
    dropdown_labels[i].appendChild(icon_to_add)
  }
})
