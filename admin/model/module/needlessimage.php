<?php
class ModelModuleNeedlessimage extends Model {
	var $tables_to_check = array(
		'banner_image' => 'image',
		'category' => 'image',
		'download' => 'filename',
		'manufacturer' => 'image',
		'option_value' => 'image',
		'order_download' => 'filename',
		'product' => 'image',
		'product_image' => 'image',
		'setting' => 'value',
		'voucher_theme' => 'image',
	);
	
	public function getImagesDb() {
		$images = array();
		$query = $this->db->query('SELECT * FROM `' . DB_PREFIX . 'needlessimage_view`');
		
		foreach ($query->rows as $row) {
			$images[] = $row['image'];
		}
		
		return $images;
	}
	
	public function getImagesFs($path, $mask = '*', $recursive = false) {
		$images = array();
		
		$directories = $recursive ? $this->getDirectoriesFs($path, true) : array($path);
		
		foreach ($directories as $directory) {
			$files = glob(rtrim(DIR_IMAGE . str_replace('../', '', $directory), '/') . '/' . $mask);
			
			if ( is_array($files) ) {
				$files = array_filter($files, 'is_file');
				$files = array_filter($files, 'filesize');
			} else {
				$files = array();
			}
			
			foreach ($files as $file) {
				$sizes = getimagesize($file);
				if (preg_match('/^image\/.*$/', $sizes['mime'])) {
					$images[] = utf8_substr($file, strlen(DIR_IMAGE));
				}
			}
		}
		
		return $images;
	}
	
	public function getImagesFsCached($file) {
		$cached_files = array();
		$file_info = pathinfo($file);
		
		$files = $this->getImagesFs('cache/'.$file_info['dirname'], $file_info['filename'].'*');
		
		foreach ($files as $cfile) {
			$current_info = pathinfo($cfile);

			if ( preg_match('/^' . $file_info['filename'] . '-[\d]+x[\d]+' . ($file_info['extension'] ? '.'.$file_info['extension'] : '') . '$/u', $current_info['basename']) ) {
				$cached_files[] = $cfile;
			}
		}
		
		return $cached_files;
	}
	
	public function getDirectoriesDb() {
		$query = $this->db->query('SELECT * FROM `' . DB_PREFIX . 'needlessimage_dir`');
		
		return $query->rows;
	}
	
	public function setDirectoriesDb($directories = array()) {
		$pieces = array();
		
		foreach ($directories as $directory) {
			$pieces[] = "(NULL, '" . $this->db->escape($directory['path']) . "', " . (int)$directory['recursive'] . ")";
		}
		
		$this->db->query('DELETE FROM `' . DB_PREFIX . 'needlessimage_dir`');
		
		if ( !empty($pieces) ) {
			$this->db->query('INSERT INTO `' . DB_PREFIX . 'needlessimage_dir` VALUES ' . implode(',', $pieces));
		}
	}
	
	public function getDirectoriesFs($root = 'data', $recursive = true) {
		$directories = array($root);
		$dirs = glob(rtrim(DIR_IMAGE . str_replace('../', '', $root), '/') . '/*', GLOB_ONLYDIR);
		
		if ($dirs) {
			foreach ($dirs as $dir) {
				$dir = utf8_substr($dir, strlen(DIR_IMAGE));
				if ($dir && $recursive) { 
					$children = $this->getDirectoriesFs($dir);
					
					if ($children) {
						foreach ($children as $child) {
							$directories[] = $child;
						}
					} else {
						$directories[] = $root . $dir;
					}
				}
			}
		}
		
		return $directories;
	}
	
	public function install($version) {
		$this->load->model('setting/setting');
		$this->model_setting_setting->editSetting('needlessimage', array('needlessimage_version' => $version));
		
		$this->db->query('DROP VIEW IF EXISTS `' . DB_PREFIX . 'needlessimage_view`');
		$sql = 'CREATE OR REPLACE VIEW `' . DB_PREFIX . 'needlessimage_view` AS ';
		$parts = array();
		
		foreach ($this->tables_to_check as $name => $column) {
			$parts[] = 'SELECT DISTINCT `' . $column . '` image FROM `' . DB_PREFIX . $name . '` WHERE `' . $column . "` LIKE 'data/%'";
		}
		
		$sql .= implode(' UNION ', $parts);
		
		$this->db->query($sql);
		
		$this->db->query('CREATE TABLE IF NOT EXISTS `' . DB_PREFIX . 'needlessimage_dir` (`directory_id` int(11) NOT NULL AUTO_INCREMENT, `path` varchar(255) COLLATE utf8_bin DEFAULT NULL,  `recursive` TINYINT(1) NOT NULL DEFAULT 0, PRIMARY KEY (`directory_id`)) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_bin');
	}
	
	public function uninstall() {
		$this->load->model('setting/setting');
		$this->model_setting_setting->editSetting('needlessimage', array());
		
		$this->db->query('DROP VIEW IF EXISTS `' . DB_PREFIX . 'needlessimage_view`');
		$this->db->query('DROP TABLE IF EXISTS `' . DB_PREFIX . 'needlessimage_dir`');
	}
}
?>