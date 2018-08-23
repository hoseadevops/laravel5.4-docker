<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Ask extends Model
{
    protected $connection = 'mysql_ask';

    private $tableName = '';

    public function __construct($tableName = 'aws_users'){

        parent::__construct();
        // 用于 获取 table
        $this->tableName = $tableName;
        // 表前缀清空
        $this->getConnection()->setTablePrefix('');

    }

    /**
     * 获取table
     * @return mixed
     */
    public function getTable(){
        return $this->tableName;
    }
}
