package volkova.restful.digest.repository

import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as MyRepository
import org.springframework.stereotype.Repository
import volkova.restful.digest.entity.Author

@Repository
interface AuthorsRepository : MyRepository<Author, Int> {

    @Query(value = """select (author_record(
                          cast_int(:id_author),
                          cast_text(:first_name),
                          cast_text(:middle_name),
                          cast_text(:surname_name)
                      )).*""",
            nativeQuery = true)
    fun findSome(
            @Param("id_author") idAuthor: Int? = null,
            @Param("first_name") firstName: String? = null,
            @Param("middle_name") middleName: String? = null,
            @Param("surname") surname: String? = null
    ): MutableList<Author>

    @Query(value = """select (author_record(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Author>

    @Query(value = """select (author_insert(
                          cast_text(:#{#author.firstName}),
                          cast_text(:#{#author.middleName}),
                          cast_text(:#{#author.surname})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("author") newAuthor: Author): Author

    @Query(value = """select (author_update(
                          cast_text(:#{#author.firstName}),
                          cast_text(:#{#author.middleName}),
                          cast_text(:#{#author.surname}),
                          cast_int(:#{#author.idAuthor})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("author") newAuthor: Author): Author

    @Query(value = """select (author_delete(cast_int(:id_author))).*""",
            nativeQuery = true)
    fun remove(@Param("id_author") idAuthor: Int): Author

}