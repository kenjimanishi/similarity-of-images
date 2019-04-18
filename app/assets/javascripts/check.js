$(function() {
    $('.form-image').submit(function() {
        if (image_id_arr.length != 2) {
            let msg = '';
            (image_id_arr.length == 1) ? msg = "Select one more image file..." : msg = "Select two image files...";
            errorAlert(msg);
            return false;
        }
    })

    Dropzone.autoDiscover = false;
    if ($('div.dropzone').length) {
        const myDropzone = new Dropzone('div.dropzone', {
            url : "/check/upload_image",
            paramName : "image[file]",
            parallelUploads : 1,
            acceptedFiles : 'image/*',
            maxFiles: 2,
            maxFilesize: 3,
            dictFileTooBig: "File size too large...\n({{filesize}}MB / Limit : {{maxFilesize}}MB)",
            dictInvalidFileType: "Image file only...",
            dictDefaultMessage: "<b>Drop files here</b><br/>or<br/><b>Click to upload</b>",
            addRemoveLinks: true,
            dictRemoveFile: "Delete",            
        }).on("success", function(file, json) {
            if (json == false) {
                console.log('[Uploading] error has occurred');
                errorAlert('Please try again few minutes later...');
                this.removeFile(file);
                return;
            }
            AddImageIdArr(json.id);
            $(file.previewTemplate).find('.dz-remove').attr('id', json.id);
            console.log('[Uploaded] ID: ' + json.id + ' / NAME: ' + file.name);
        }).on("removedfile", function(file) {
            const id = $(file.previewTemplate).find('.dz-remove').attr('id');
            $.ajax({
                type: 'DELETE',
                url: '/check/delete_image/',
                dataType: "json",
                data: {"image_id":id}
            })
            .done(function(data) {
                if (data == false) console.log('[Removing] error has occurred');
                removeImageIdArr(id);
                console.log('[Removed] ID: ' + id + ' / NAME: ' + file.name);
            })
            .fail(function() {
                console.log('[Removing] connection failed');
            });
        }).on("addedfile", function() {
            if (this.files[2] != null) {
                this.removeFile(this.files[0]);
            }
        }).on("error", function(file, msg) {
            errorAlert(msg);
            this.removeFile(file);
        });
    }
});

let image_id_arr = [];

function errorAlert(msg) {
    swal("Error", msg);
}

function AddImageIdArr(id) {
    image_id_arr.push(id);
    if (image_id_arr.length > 2) image_id_arr.shift();
    setImageId();
}

function removeImageIdArr(id) {
    image_id_arr.some(function(v, i) {
        if (v == id) image_id_arr.splice(i,1);    
    });
    setImageId();
}

function setImageId() {
    $("#image_id").val(image_id_arr.join(','));
}
