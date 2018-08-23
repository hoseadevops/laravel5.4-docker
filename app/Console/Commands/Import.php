<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

use App\Ask;
use App\Collection;

use DB;

class Import extends Command
{
    private $page_size = 30;

    const TYPE_CODE = 'biask';
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'armors:ask:import';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = '导入数据';

    private static $mockUser = [
        'user_name' => '',
        'email' => '',
        'avatar_file' => '',

        'mobile' => '',
        'password' => '4bda5eeafcd5ef7c37a5bb888ffc53c5',
        'salt' => 'nwmc',
        'sex' => '1',

        'reg_time' => '1533887441',
        'reg_ip' => '610717817',
        'last_login' => '1534746770',
        'last_ip' => '2886926337',
        'online_time' => '15770',
        'last_active' => '1534746975',

        'group_id'  => 4,
        'reputation_group' => 5,
        'valid_email' => 1,

        'is_first_login' => 0,
        'reputation_update_time' => '1534746765',

        'email_settings'=> 'a:2:{s:9:"FOLLOW_ME";s:1:"N";s:10:"NEW_ANSWER";s:1:"N";}',
   ];
    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * @param $page
     * @return mixed
     * @desc 返回skip
     */
    protected function getSkip($page=1)
    {
        return ( max(0, $page -1) ) * $this->page_size;
    }


    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        //$this->processTopic();
        //$this->processUser();
        //$this->processQuestion();

        $this->processAnswer();
    }



    private function processQuestion()
    {
        $collection_questions = new Collection('question');
        $collection_tags      = new Collection('tags');
        $ask_relationship     = new Ask('aws_collection_relationship');

        $total = $collection_questions->count( );

        $isOpen = false;

        if ( $total > 0 )
        {
            $max_page = ceil($total / $this->page_size);

            for ($page = 1; $page <= $max_page; $page++)
            {
                $data = $collection_questions->skip($this->getSkip($page))->take($this->page_size)->get()->toArray();

                foreach ($data as $key => $value)
                {
                    $dataQuestion             = [];
                    $value['published_uid']   = empty($value['published_uid']) ? 999999999999 : $value['published_uid'];
                    $userIdObj                = $ask_relationship->where(['origin_uid'=> $value['published_uid'], 'origin'=> 'biask'])->first();
                    $value['published_uid']   = empty($userIdObj) ? 1 : $userIdObj->uid;

                    $dataQuestion['question'] = $value;

                    $topics                   = $collection_tags->where(['question_id'=> $value['question_id']])->get()->toArray();

                    if(!empty($topics))
                    {
                        $topics               = array_column($topics, 'label');

                        $ask_topics           = new Ask('aws_topic');

                        $topics               = $ask_topics->whereIn('topic_title', $topics)->get(['topic_id'])->toArray();
                        if(!empty($topics))
                        {
                            $topics                 = array_column($topics, 'topic_id');

                            $dataQuestion['topics'] = $topics;
                        }
                    }


                    if($value['question_id'] == 2551)
                    {
                        $isOpen = true;
                    }

                    if($isOpen === false)
                    {
                        continue;
                    }

                    $isSaved= $this->saveQuestion($dataQuestion);

                    if(!$isSaved)
                    {
                        echo print_r($dataQuestion, true);
                        die;
                    }
                    else
                    {
                        echo '成功 :' .$value['question_id'] . "\n";
                    }
                }
            }

        }
    }

    private function getCat($topic_id = 1){

        $return  = [
            5    => 2,
            21   => 3,
            6    => 4,
            42   => 5,
            225  => 6,
        ];

        return isset($return[$topic_id]) ? $return[$topic_id]  : '';

    }
    private function saveQuestion($dataQuestion = [], $type = self::TYPE_CODE)
    {
        $ask_questions        = new Ask('aws_question');

        try{

            DB::connection('mysql_ask')->beginTransaction();

            if(isset($dataQuestion['question']) && $question = $dataQuestion['question'])
            {
                $question['add_time']     = strtotime($question['add_time']);
                $question['update_time']  = $question['add_time'];

                $origin_question_id = $question['question_id'];

                unset($question['question_id']);

                $is = DB::connection('mysql_ask')->table('aws_question')->insert($question);

                if(!$is)
                {
                    throw new  \Exception('存储失败1');
                }

                $question_id = $ask_questions->max('question_id');

                if(isset($dataQuestion['topics']) && $topic = $dataQuestion['topics'])
                {
                    $topics = [];

                    foreach ($topic as $k => $topic_id)
                    {
                        $topics[$k]['topic_id'] = $topic_id;
                        $topics[$k]['item_id']  = $question_id;
                        $topics[$k]['add_time'] = $question['add_time'];
                        $topics[$k]['uid']      = $question['published_uid'];
                        $topics[$k]['type']     = 'question';

                        $catId = $this->getCat($topic_id);
                    }

                    $is = DB::connection('mysql_ask')->table('aws_topic_relation')->insert($topics);

                    if(!$is)
                    {
                        throw new  \Exception('存储失败2');
                    }
                }

                $catId = (isset($catId) && !empty($catId)) ? $catId : 1;

                $is = DB::connection('mysql_ask')->table('aws_question')->where(['question_id'=> $question_id])->update(['category_id'=> $catId]);

                if(!$is)
                {
                    throw new  \Exception('存储失败4');
                }

                $posts = [
                    'post_id'    => $question_id,
                    'post_type'  => 'question',
                    'add_time'   => $question['add_time'],
                    'update_time'=> $question['add_time'],
                    'category_id'=> $catId,
                    'uid'        => $question['published_uid']
                ];

                $is = DB::connection('mysql_ask')->table('aws_posts_index')->insert($posts);

                if(!$is)
                {
                    throw new  \Exception('存储失败3');
                }




                $is = DB::connection('mysql_ask')->table('aws_collection_relationship')->insert([
                    'uid'         => $question_id,
                    'origin'      => $type . '_question',
                    'origin_uid'  => $origin_question_id,
                ]);

                if(!$is)
                {
                    throw new \Exception('存储失败5');
                }


                DB::connection('mysql_ask')->commit();

            }

            return true;

        }catch (\Exception $e) {

            echo print_r([$e->getLine(), $e->getMessage()]);

            DB::connection('mysql_ask')->rollBack();

            return false;
        }
    }

    private function processAnswer()
    {
        $collection_answer = new Collection('answer');

        $total             = $collection_answer->count( );

        $isOpen            = false;

        if ( $total > 0 )
        {
            $max_page = ceil($total / $this->page_size);

            for ($page = 1; $page <= $max_page; $page++)
            {
                $data = $collection_answer->skip($this->getSkip($page))->take($this->page_size)->get()->toArray();

                foreach ($data as $key => $value)
                {

                    if($value['id'] == 17)
                    {
                        $isOpen = true;
                    }

                    if($isOpen === false)
                    {
                        continue;
                    }

                    $isSaved = $this->saveAnswer($value);

                    if(!$isSaved)
                    {
                        echo print_r($value, true);
                        die;
                    }
                    else
                    {
                        echo '成功 :' .$value['id'] . "\n";
                    }
                }
            }
        }
    }

    private function saveAnswer($data, $type = self::TYPE_CODE)
    {
        $ask_relationship  = new Ask('aws_collection_relationship');
        $aws_question      = new Ask('aws_question');
        $id                = $data['id'];

        $logs              = [];

        try {

            $question_id = $data['question_id'];
            $uid         = $data['uid'];

            $question_id_obj = $ask_relationship->where([
                'origin' => 'biask_question',
                'origin_uid' => $question_id
            ])->first();

            if(empty($question_id_obj))
            {
                echo 'unfind ：' . $id . "\n";

                return true;
            }

            $ask_question_id = $question_id_obj->uid;

            $ask_user_id_obj = $ask_relationship->where(['origin' => 'biask', 'origin_uid' => $uid])->first();

            if(empty($ask_user_id_obj))
            {
                echo 'unfind ：' . $id . "\n";

                return true;
            }


            $ask_user_id = $ask_user_id_obj->uid;


            $data = [
                'question_id'    => $ask_question_id,
                'answer_content' => $data['message'],
                'add_time'       => strtotime($data['time']),
                'uid'            => $ask_user_id,
                'category_id' => $aws_question->where(['question_id' => $ask_question_id])->first()->category_id
            ];

            $is = DB::connection('mysql_ask')->table('aws_answer')->insert($data);

            if(!$is)
            {
                throw new \Exception('存储失败');
            }

            $answer_id = DB::connection('mysql_ask')->table('aws_answer')->max('answer_id');

            $is = DB::connection('mysql_ask')->table('aws_collection_relationship')->insert([
                'uid'         => $answer_id,
                'origin'      => $type . '_answer',
                'origin_uid'  => $id,
            ]);

            if(!$is)
            {
                throw new \Exception('存储失败5');
            }

            return true;

        }catch (\Exception $e){

            echo print_r([$e->getLine(), $e->getMessage()]);

            return false;
        }

    }

    private function processTopic(){
        $this->saveTopic();
    }

    private function saveTopic()
    {
        $data = DB::connection('mysql_collection')->select('select count(*) AS count, label from tags GROUP BY label ORDER BY count DESC');

        foreach ($data as $key => $value)
        {
            DB::connection('mysql_ask')->table('topic')->insert([
                'topic_title'       => $value->label,
                'topic_description' => $value->label
            ]);
        }
    }

    private function processUser(){

        $collection_users = new Collection('user');

        $total            = $collection_users->count();

        if( $total > 0 )
        {
            $max_page = ceil($total / $this->page_size);

            for ( $page = 1; $page <= $max_page; $page++ )
            {
                $data = $collection_users->skip($this->getSkip($page))->take($this->page_size)->get()->toArray();

                foreach ($data as $key => $value)
                {
                    if(strpos($value['avatar_file'], '/uploads/avatar') !== false)
                    {
                        $data[$key]['avatar_file'] = str_replace('./uploads', self::TYPE_CODE, $value['avatar_file']);
                    }
                    else
                    {
                        $data[$key]['avatar_file'] = '';
                    }

                    if(strpos($value['introduction'], 'yoyow') !== false)
                    {
                        $data[$key]['introduction'] = str_replace('yoyow','Armors', $value['introduction']);
                    }

                    $isSaved = $this->saveUser($data[$key], self::TYPE_CODE, $value['id']);

                    if(!$isSaved)
                    {
                        echo print_r($value, true);
                        die;
                    }
                    else
                    {
                        echo '成功 :' .$value['id'] . "\n";
                    }
                }
            }
        }
    }

    /*
     * 存储
     **/
    private function saveUser($data = [], $type = self::TYPE_CODE, $id){

        $ask_users        = new Ask('aws_users');

        $data             = $this->assemblyUser($data);

        $max_id           = $ask_users->max('uid');

        $data['email']    = 'c' . $this->generateRandomString(5) .$type . ($max_id+1) . '@cai.com';

        $data['uid']      = ($max_id+1);

        try{
            DB::connection('mysql_ask')->beginTransaction();

            $is = DB::connection('mysql_ask')->table('aws_users')->insert($data);

            if(!$is)
            {
                throw new  \Exception('存储失败1');
            }

            $is = DB::connection('mysql_ask')->table('aws_collection_relationship')->insert([
                'uid'         => ($max_id+1),
                'origin'      => $type,
                'origin_uid'  => $id,
            ]);

            if(!$is)
            {
                throw new \Exception('存储失败1');
            }

            DB::connection('mysql_ask')->commit();

            return true;

        }catch (\Exception $e) {

            echo print_r([$e->getLine(), $e->getMessage()]);

            DB::connection('mysql_ask')->rollBack();

            return false;
        }

    }

    /*
     * 组装数据
     **/
    private function assemblyUser($data = []){
        $item = self::$mockUser;

        $item['user_name']   = $data['user_name'];
        $item['avatar_file'] = $data['avatar_file'];

        return $item;
    }

    private function generateRandomString($length = 10) {
        $characters = '012345678abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $randomString = '';
        for ($i = 0; $i < $length; $i++) {
            $randomString .= $characters[rand(0, strlen($characters) - 1)];
        }
        return $randomString;
    }

}
