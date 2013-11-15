<?php echo $header; ?> 
<div id="content">
	<div class="breadcrumb">
		<?php foreach ($breadcrumbs as $breadcrumb) { ?> 
			<?php echo $breadcrumb['separator']; ?><a href="<?php echo $breadcrumb['href']; ?>"><?php echo $breadcrumb['text']; ?></a>
		<?php } ?> 
	</div>
	<?php if ($error_warning) { ?> 
		<div class="warning"><?php echo $error_warning; ?></div>
	<?php } ?> 
	<div class="box">
		<div class="heading">
			<h1><img src="view/image/module.png" alt="" /> <?php echo $heading_title; ?></h1>
			<div class="buttons"><a onclick="$('#form').submit();" class="button"><?php echo $button_save; ?></a><a onclick="location = '<?php echo $cancel; ?>';" class="button"><?php echo $button_cancel; ?></a></div>
		</div>
		<div class="content">
			<form action="<?php echo $action; ?>" method="post" enctype="multipart/form-data" id="form">
				<table id="directory" class="list">
					<thead>
						<tr>
							<td class="left"><?php echo $entry_directory; ?></td>
							<td class="left"><?php echo $entry_recursive; ?></td>
							<td></td>
						</tr>
					</thead>
					<?php foreach ($directories as $directory_row => $directory) { ?> 
						<tbody id="directory-row<?php echo $directory_row; ?>">
							<tr>
								<td class="left">
									<select name="directory[<?php echo $directory_row ?>][path]">
										<option value=""><?php echo $text_select_dir; ?></option>
										<?php foreach($directories_fs as $directory_fs) { ?> 
											<option value="<?php echo $directory_fs; ?>"<?php echo $directory_fs == $directory['path'] ? ' selected="selected"' : ''; ?>><?php echo $directory_fs; ?></option>
										<?php } ?>
									</select>
									<?php //print_r($directories_fs); ?>
								</td>
								<td class="left">
									<select name="directory[<?php echo $directory_row ?>][recursive]">
										<option value="0"><?php echo $text_no; ?></option>
										<option value="1"<?php echo $directory['recursive'] ? ' selected="selected"' : ''; ?>><?php echo $text_yes; ?></option>
									</select>
								</td>
								<td class="left">
									<a onclick="$('#directory-row<?php echo $directory_row; ?>').remove();" class="button"><?php echo $button_remove; ?></a>
								</td>
							</tr>
						</tbody>
					<?php } ?> 
					<tfoot>
						<tr>
							<td colspan="2"></td>
							<td class="left"><a onclick="addDirectory();" class="button"><?php echo $button_add_dir; ?></a></td>
						</tr>
					</tfoot>
				</table>
			</form>
			<table id="analyze" class="list">
				<tfoot>
					<tr>
						<td class="center">
							<a onclick="analyze();" class="button" style="font-size:1.3em;"><?php echo $button_analyze; ?></a>
						</td>
					</tr>
				</tfoot>
			</table>
		</div>
	</div>
</div>
<script type="text/javascript"><!--
var directory_row = <?php echo isset($directory_row) ? ++$directory_row : 0; ?>;

function addDirectory() {
	var html = '';
	
	html  = '<tbody id="directory-row' + directory_row + '">';
	html += '	<tr>';
	html += '		<td class="left">';
	html += '			<select name="directory[' + directory_row + '][path]" id="directory' + directory_row + '">';
	html += '				<option value=""><?php echo $text_select_dir; ?></option>';
	<?php foreach($directories_fs as $directory_fs) { ?> 
	html += '				<option value="<?php echo $directory_fs; ?>"><?php echo $directory_fs; ?></option>';
	<?php } ?> 
	html += '			</select>';
	html += '		</td>';
	html += '		<td class="left">';
	html += '			<select name="directory[' + directory_row + '][recursive]">';
	html += '				<option value="0"><?php echo $text_no; ?></option>';
	html += '				<option value="1"><?php echo $text_yes; ?></option>';
	html += '			</select>';
	html += '		</td>';
	html += '		<td class="left">';
	html += '			<a onclick="$(\'#directory-row' + directory_row + '\').remove();" class="button"><?php echo $button_remove; ?></a>';
	html += '		</td>';
	html += '	</tr>';
	html += '</tbody>';
	
	$('#directory tfoot').before(html);
	
	directory_row++;
}

function analyze() {
	var post_data = $('#form').serialize();
	var html = '';
	var inner_html = '';
	
	$('#analyze thead, #analyze tbody').remove();
	
	$("#form select[name*='[path]']").each(function(index){
		html += '<thead id="analyze-head-' + index + '"' + ($(this).val() == '' ? ' style="display:none;"' : '') + '>';
		html += '	<tr>';
		html += '		<td class="left">' + $(this).val() + ($("#form select[name*='[" + index + "][recursive]']").val() == 1 ? ' <span style="font-weight:normal;">(+ <?php echo utf8_strtolower($entry_recursive); ?>)</span>' : '') + '</td>';
		html += '	</tr>';
		html += '</thead>';
		html += '<tbody id="analyze-body-' + index + '"' + ($(this).val() == '' ? ' style="display:none;"' : '') + '>';
		html += '	<tr>';
		html += '		<td class="center"><img src="view/image/loading.gif" class="loading"></td>';
		html += '	</tr>';
		html += '</tbody>';
	});
	
	$('#analyze tfoot').before(html);
	
	$.ajax({
		url: 'index.php?route=module/needlessimage/analyze&token=<?php echo $token; ?>',
		type: 'post',
		data: post_data,
		dataType: 'json',
		success: function(json) {
			if (json) {
				var dir_length = json.length;
				
				for (var i = 0; i < dir_length; i++) {
					files_length = json[i].length;
					if (files_length) {
						inner_html  = prepareCheckboxesForm(json[i], i);
					} else {
						inner_html = '<div class="attention" style="display: inline-block;"><?php echo $text_no_files_to_delete; ?></div>'
					}
					
					$('#analyze-body-' + i + ' td').html(inner_html);
				}
			} else {
				inner_html  = '<tbody>';
				inner_html += '	<tr>';
				inner_html += '		<td class="center"><div class="warning" style="display: inline-block;"><?php echo $error_error; ?></div></td>';
				inner_html += '	</tr>';
				inner_html += '</tbody>';
				
				$('#analyze thead, #analyze tbody').remove();
				$('#analyze tfoot').before(inner_html);
			}
		},
		error: function(xhr, ajaxOptions, thrownError) {
			alert(thrownError + "\r\n" + xhr.statusText + "\r\n" + xhr.responseText);
		}
	});
}

function deleteFiles(index) {
	var post_data = $('#form-delete-' + index).serialize();
	var html = '';
	
	$('#analyze-body-' + index + ' td').html('<img src="view/image/loading.gif" class="loading">');
	
	$.ajax({
		url: 'index.php?route=module/needlessimage/delete&token=<?php echo $token; ?>',
		type: 'post',
		data: post_data,
		dataType: 'json',
		success: function(json) {
			if (json.data.length) {
				html = prepareCheckboxesForm(json.data, index, json.message);
			} else {
				html = '<div style="display: inline-block;">' + json.message + '</div>';
			}
			
			$('#analyze-body-' + index + ' td').html(html);
		},
		error: function(xhr, ajaxOptions, thrownError) {
			alert(thrownError + "\r\n" + xhr.statusText + "\r\n" + xhr.responseText);
		}
	});
}

function prepareCheckboxesList(checkboxes) {
	var output = '';
	var odd = 'odd';
	
	for (var i = 0; i < checkboxes.length; i++) {
		odd = odd == 'odd' ? 'even' : 'odd';
		output += '		<div class="' + odd + '">';
		output += '			<input name="delete[]" type="checkbox" value="' + checkboxes[i]['path'] + '"> ' + checkboxes[i]['name'];
		output += '		</div>';
	}
	
	return output;
}

function prepareCheckboxesForm(data, index, message) {
	var output = '';
	
	if (typeof message === 'undefined') {
		message = '';
	}
	
	output += '<form id="form-delete-' + index + '" action="<?php echo $action_delete ?>" method="post" enctype="multipart/form-data" class="left" style="display:inline-block;">';
	output += message;
	output += '	<input type="hidden" value="' + $("#form select[name*='[" + index + "][path]']").val() + '" name="path">';
	output += '	<input type="hidden" value="' + $("#form select[name*='[" + index + "][recursive]']").val() + '" name="recursive">';
	output += '	<div class="scrollbox" style="width:700px;height:200px;">';
	output += prepareCheckboxesList(data);
	output += '	</div>';
	output += '	<div class="right">';
	output += '		<a onclick="deleteFiles(' + index + ');" class="button"><?php echo $button_delete_selected; ?></a> <a onclick="selectAll(\'#form-delete-' + index + '\');" class="button" style="background-color: #fff; color: #000; border: 1px solid #ddd; font-weight: bold;"><?php echo $button_select_all; ?></a> <a onclick="unselectAll(\'#form-delete-' + index + '\');" class="button" style="background-color: #fff; color: #000; border: 1px solid #ddd; font-weight: bold;"><?php echo $button_unselect_all; ?></a>';
	output += '	</div>';
	output += '</form>';
	
	return output;
}

function selectAll(form_id) {
	$(form_id).find(':checkbox').attr('checked', true);
}

function unselectAll(form_id) {
	$(form_id).find(':checkbox').attr('checked', false);
}
//--></script> 
<?php echo $footer; ?>