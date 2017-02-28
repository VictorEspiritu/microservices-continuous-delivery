<?php

use PHPUnit\Framework\TestCase;

final class ControllerTest extends TestCase
{
    /**
     * @test
     */
    public function it_returns_a_nice_message()
    {
        $controller = new Controller();

        $this->assertEquals(
            'Continuous delivery is great!',
            $controller->indexAction()
        );
    }
}
